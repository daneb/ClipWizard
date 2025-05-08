import Foundation
import SwiftUI
import AppKit
import Compression

enum ClipboardItemType: String, Codable {
    case text
    case image
    case unknown
}

class ClipboardItem: Identifiable, ObservableObject {
    let id = UUID()
    let timestamp: Date
    let type: ClipboardItemType
    
    @Published var originalText: String?
    @Published var sanitizedText: String?
    @Published var originalImage: NSImage?
    
    // Memory management
    private var compressedTextData: Data?
    private var compressedImageData: Data?
    private var isTextCompressed = false
    private var isImageUnloaded = false
    
    // Image file reference for lazy loading
    private var imageFilePath: URL?
    
    // A reference to the clipboard monitor (type-erased to avoid circular dependencies)
    var typeErasedClipboardMonitor: AnyObject?
    
    var isSanitized: Bool {
        return originalText != sanitizedText && originalText != nil && sanitizedText != nil
    }
    
    init(text: String, timestamp: Date = Date()) {
        self.originalText = text
        self.sanitizedText = text  // Initially the same, will be sanitized later if needed
        self.timestamp = timestamp
        self.type = .text
    }
    
    init(image: NSImage, timestamp: Date = Date()) {
        self.originalImage = image
        self.timestamp = timestamp
        self.type = .image
        
        // For images, we should immediately persist to disk to avoid memory issues
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            // Save image to file system
            if let imagePath = FileStorageManager.shared.saveImage(image, withId: self.id.uuidString) {
                self.imageFilePath = URL(fileURLWithPath: imagePath)
                
                // We could unload the image now, but we'll wait until memory pressure occurs
                // or when the item is scrolled off-screen
            }
        }
    }
}

extension ClipboardItem: Equatable, Hashable {
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Memory Management Extensions

extension ClipboardItem {
    /// Unloads the image from memory while keeping a reference that can be reloaded when needed
    func unloadImage() {
        guard type == .image, let image = originalImage, !isImageUnloaded else { return }
        
        // Ensure we have a file reference for later reloading
        if imageFilePath == nil {
            // Save image to file system if not already saved
            if let imagePath = FileStorageManager.shared.saveImage(image, withId: id.uuidString) {
                imageFilePath = URL(fileURLWithPath: imagePath)
            } else if compressedImageData == nil, let tiffData = image.tiffRepresentation {
                // Fallback: store the image data in memory
                compressedImageData = tiffData
            } else {
                // We can't unload without either a file reference or compressed data
                return
            }
        }
        
        // Release the image
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.originalImage = nil
            self.isImageUnloaded = true
        }
        
        logInfo("Unloaded image from memory for item \(id.uuidString)")
    }
    
    /// Reloads the image when needed
    /// - Parameter completion: Closure called with the loaded image or nil if loading failed
    func reloadImage(completion: ((NSImage?) -> Void)? = nil) {
        // If already loaded, just return the image
        if let image = originalImage {
            completion?(image)
            return
        }
        
        // Only proceed for image type items that are unloaded
        guard type == .image, isImageUnloaded else {
            completion?(nil)
            return
        }
        
        // Use a background queue for loading
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion?(nil)
                }
                return
            }
            
            var loadedImage: NSImage? = nil
            
            // Try to load from file path first (preferred for larger images)
            if let filePath = self.imageFilePath {
                loadedImage = FileStorageManager.shared.loadImage(withId: self.id.uuidString)
            }
            
            // Fall back to in-memory compressed data if file loading failed
            if loadedImage == nil, let imageData = self.compressedImageData {
                loadedImage = NSImage(data: imageData)
            }
            
            // Update properties on the main thread
            DispatchQueue.main.async {
                if let image = loadedImage {
                    self.originalImage = image
                    self.isImageUnloaded = false
                    logInfo("Reloaded image for item \(self.id.uuidString)")
                } else {
                    logError("Failed to reload image for item \(self.id.uuidString)")
                }
                
                // Call completion handler
                completion?(loadedImage)
            }
        }
    }
    
    /// Synchronous version of reloadImage - use when needed but async version is preferred
    /// - Returns: The loaded image or nil if loading failed
    func reloadImage() -> NSImage? {
        // Return immediately if already loaded
        if let image = originalImage {
            return image
        }
        
        guard type == .image, isImageUnloaded else { return nil }
        
        // Try to reload from file path
        if let filePath = imageFilePath {
            if let image = FileStorageManager.shared.loadImage(withId: id.uuidString) {
                originalImage = image
                isImageUnloaded = false
                return image
            }
        }
        
        // Try to reload from compressed data
        if let imageData = compressedImageData, let image = NSImage(data: imageData) {
            originalImage = image
            isImageUnloaded = false
            return image
        }
        
        return nil
    }
    
    /// Compresses text to save memory for large text items
    /// - Parameter forceCompress: If true, compress regardless of size
    /// - Returns: True if text was compressed, false otherwise
    @discardableResult
    func compressText(forceCompress: Bool = false) -> Bool {
        guard type == .text, let text = originalText, !isTextCompressed, 
              (text.count > 1000 || forceCompress) else { return false }
        
        // Compress text data
        if let textData = text.data(using: .utf8) {
            compressedTextData = compress(data: textData)
            originalText = nil
            isTextCompressed = true
            return true
        }
        
        return false
    }
    
    /// Decompresses text when needed
    func decompressText() -> String? {
        guard type == .text, isTextCompressed, let compressedData = compressedTextData else { return originalText }
        
        if let decompressedData = decompress(data: compressedData),
           let text = String(data: decompressedData, encoding: .utf8) {
            originalText = text
            isTextCompressed = false
            return text
        }
        
        return nil
    }
    
    /// Cleans up resources when an item is being deleted
    func cleanup() {
        // Clean up any stored image file
        if type == .image, let filePath = imageFilePath?.path ?? nil {
            _ = FileStorageManager.shared.deleteImage(withId: id.uuidString)
        }
        
        // Clear any in-memory caches
        compressedImageData = nil
        compressedTextData = nil
        originalImage = nil
        
        // Clear circular references
        typeErasedClipboardMonitor = nil
    }
    
    /// Sets a file reference for the image instead of keeping it in memory
    func setImageFilePath(_ path: URL) {
        imageFilePath = path
    }
    
    // MARK: - Private Helper Methods
    
    private func compress(data: Data) -> Data {
        let sourceSize = data.count
        // Add 1% to destination buffer size to ensure it's large enough
        let destinationSize = sourceSize + (sourceSize / 100)
        
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationSize)
        defer { destinationBuffer.deallocate() }
        
        let sourceBuffer = (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: sourceSize)
        
        let compressedSize = compression_encode_buffer(
            destinationBuffer, destinationSize,
            sourceBuffer, sourceSize,
            nil,
            COMPRESSION_LZFSE
        )
        
        return Data(bytes: destinationBuffer, count: compressedSize)
    }
    
    private func decompress(data compressedData: Data) -> Data? {
        // Estimate decompressed size (original size is typically larger than compressed)
        // We'll estimate 2x the compressed size as a starting point
        let sourceSize = compressedData.count
        let destinationSize = sourceSize * 2
        
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationSize)
        defer { destinationBuffer.deallocate() }
        
        let sourceBuffer = (compressedData as NSData).bytes.bindMemory(to: UInt8.self, capacity: sourceSize)
        
        let decompressedSize = compression_decode_buffer(
            destinationBuffer, destinationSize,
            sourceBuffer, sourceSize,
            nil,
            COMPRESSION_LZFSE
        )
        
        guard decompressedSize > 0 else { return nil }
        return Data(bytes: destinationBuffer, count: decompressedSize)
    }
}
