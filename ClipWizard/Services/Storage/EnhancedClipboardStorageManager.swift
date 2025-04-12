import Foundation
import AppKit
import Compression
import SQLite3

/// Enhanced manager for persisting clipboard history using SQLite database
class EnhancedClipboardStorageManager {
    // Singleton instance
    static let shared = EnhancedClipboardStorageManager()
    
    // Configuration constants
    private let maxTextSize = 2 * 1024 * 1024 // 2MB max text size
    private let maxPersistedItems = 200 // Maximum number of items to keep
    private let autoCleanupThreshold = 150 // Threshold for auto cleanup
    
    // Database access
    private let clipboardItemDAO = ClipboardItemDAO()
    
    // Background queue for processing
    private let processingQueue = DispatchQueue(label: "com.clipwizard.storage.processing", qos: .utility)
    
    private init() {
        // Initialize storage manager
    }
    
    // MARK: - Public Methods
    
    /// Saves a clipboard item to the database
    /// - Parameter item: The ClipboardItem to save
    /// - Returns: True if successful, false otherwise
    func saveClipboardItem(_ item: ClipboardItem) -> Bool {
        // First, handle size limits
        if item.type == .text, let text = item.originalText, text.count > maxTextSize {
            logWarning("Text is too large (\(text.count) chars), compressing before storage")
            
            // Compress large text before storage
            guard let compressedText = compressText(text) else {
                logError("Failed to compress large text for storage")
                return false
            }
            
            item.originalText = compressedText
            
            // Also compress sanitized text if it exists and is large
            if let sanitizedText = item.sanitizedText, sanitizedText.count > maxTextSize {
                guard let compressedSanitized = compressText(sanitizedText) else {
                    logError("Failed to compress large sanitized text")
                    return false
                }
                item.sanitizedText = compressedSanitized
            }
        }
        
        // Save the item
        let success = clipboardItemDAO.save(item)
        
        if success {
            logInfo("Successfully saved clipboard item to database")
            
            // Check if we need to clean up old items
            processingQueue.async {
                self.performAutoCleanup()
            }
        } else {
            logError("Failed to save clipboard item to database")
        }
        
        return success
    }
    
    /// Updates an existing clipboard item
    /// - Parameter item: The ClipboardItem to update
    /// - Returns: True if successful, false otherwise
    func updateClipboardItem(_ item: ClipboardItem) -> Bool {
        return clipboardItemDAO.update(item)
    }
    
    /// Loads all clipboard history from the database
    /// - Parameters:
    ///   - limit: Maximum number of items to retrieve
    ///   - searchText: Optional text to filter by
    /// - Returns: Array of ClipboardItem objects
    func loadClipboardHistory(limit: Int = 100, searchText: String? = nil) -> [ClipboardItem] {
        let items = clipboardItemDAO.getAll(
            limit: limit,
            searchText: searchText,
            sortBy: "timestamp",
            ascending: false
        )
        
        // Decompress any compressed text
        for item in items where item.type == .text {
            if let originalText = item.originalText, isCompressedText(originalText) {
                item.originalText = decompressText(originalText) ?? originalText
            }
            
            if let sanitizedText = item.sanitizedText, isCompressedText(sanitizedText) {
                item.sanitizedText = decompressText(sanitizedText) ?? sanitizedText
            }
        }
        
        return items
    }
    
    /// Counts the total number of clipboard items
    /// - Parameter searchText: Optional text to filter by
    /// - Returns: The count of clipboard items
    func countClipboardItems(searchText: String? = nil) -> Int {
        return clipboardItemDAO.count(searchText: searchText)
    }
    
    /// Deletes a clipboard item
    /// - Parameter item: The ClipboardItem to delete
    /// - Returns: True if successful, false otherwise
    func deleteClipboardItem(_ item: ClipboardItem) -> Bool {
        return clipboardItemDAO.delete(item)
    }
    
    /// Clears all clipboard history
    /// - Returns: True if successful, false otherwise
    func clearClipboardHistory() -> Bool {
        return clipboardItemDAO.deleteAll()
    }
    
    /// Cleans up old clipboard items
    /// - Parameter olderThan: Optional date to use as cutoff
    /// - Returns: True if successful, false otherwise
    func cleanupOldItems(olderThan: Date? = nil) -> Bool {
        if let date = olderThan {
            return clipboardItemDAO.deleteItemsOlderThan(date)
        } else {
            // If no date provided, keep only the most recent items up to maxPersistedItems
            let totalCount = clipboardItemDAO.count()
            
            if totalCount > maxPersistedItems {
                // Get all items sorted by timestamp
                let allItems = clipboardItemDAO.getAll(
                    limit: totalCount,
                    sortBy: "timestamp",
                    ascending: true
                )
                
                // Calculate how many items to delete
                let itemsToDelete = totalCount - maxPersistedItems
                
                // Get the items to delete (oldest first)
                let itemsToRemove = Array(allItems.prefix(itemsToDelete))
                
                // Delete each item
                var success = true
                for item in itemsToRemove {
                    if !clipboardItemDAO.delete(item) {
                        success = false
                    }
                }
                
                return success
            }
            
            // No cleanup needed
            return true
        }
    }
    
    /// Performs automatic cleanup if threshold is reached
    private func performAutoCleanup() {
        let totalCount = clipboardItemDAO.count()
        
        if totalCount > autoCleanupThreshold {
            logInfo("Auto cleanup triggered: \(totalCount) items exceeds threshold of \(autoCleanupThreshold)")
            _ = cleanupOldItems()
        }
    }
    
    // MARK: - Import/Export Methods
    
    /// Imports clipboard history from a file
    /// - Parameter url: URL of the file to import
    /// - Returns: Result with the number of items imported or an error
    func importFromFile(url: URL) -> Result<Int, Error> {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            
            // Try to decode as an array of CodableClipboardItem
            let items = try decoder.decode([CodableClipboardItem].self, from: data)
            
            var importedCount = 0
            
            // Import each item
            for codableItem in items {
                if let item = codableItem.toClipboardItem() {
                    if clipboardItemDAO.save(item) {
                        importedCount += 1
                    }
                }
            }
            
            return .success(importedCount)
        } catch {
            return .failure(error)
        }
    }
    
    /// Exports clipboard history to a file
    /// - Parameter url: URL where to save the export
    /// - Returns: Result with success or an error
    func exportToFile(url: URL) -> Result<Void, Error> {
        do {
            // Get all items
            let items = clipboardItemDAO.getAll(limit: maxPersistedItems)
            
            // Convert to codable format
            let codableItems = items.map { CodableClipboardItem(from: $0) }
            
            // Encode to JSON
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(codableItems)
            
            // Write to file
            try data.write(to: url)
            
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Text Compression Methods
    
    /// Compresses text to save storage space
    /// - Parameter text: The text to compress
    /// - Returns: Compressed text with a marker, or nil if compression failed
    private func compressText(_ text: String) -> String? {
        guard let data = text.data(using: .utf8) else { return nil }
        
        // Create destination buffer with some extra space for compression overhead
        let bufferSize = data.count + 1024
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { destinationBuffer.deallocate() }
        
        // Compress the data
        let compressedSize = data.withUnsafeBytes { sourceBuffer in
            compression_encode_buffer(
                destinationBuffer,
                bufferSize,
                sourceBuffer.bindMemory(to: UInt8.self).baseAddress!,
                data.count,
                nil,
                COMPRESSION_LZFSE
            )
        }
        
        guard compressedSize > 0 else { return nil }
        
        // Create data from the compressed buffer
        let compressedData = Data(bytes: destinationBuffer, count: compressedSize)
        
        // Encode to Base64 for safe storage
        let base64String = compressedData.base64EncodedString()
        
        // Add a marker so we know it's compressed
        return "COMPRESSED:" + base64String
    }
    
    /// Checks if text is compressed
    /// - Parameter text: The text to check
    /// - Returns: True if the text is compressed
    private func isCompressedText(_ text: String) -> Bool {
        return text.hasPrefix("COMPRESSED:")
    }
    
    /// Decompresses text that was previously compressed
    /// - Parameter text: The compressed text
    /// - Returns: The original decompressed text, or nil if decompression failed
    private func decompressText(_ text: String) -> String? {
        // Check if this is actually compressed text
        guard isCompressedText(text) else { return text }
        
        // Remove the marker
        let base64String = String(text.dropFirst("COMPRESSED:".count))
        
        // Decode the Base64 string
        guard let compressedData = Data(base64Encoded: base64String) else { return nil }
        
        // Estimate decompressed size (approximate)
        let estimatedDecompressedSize = compressedData.count * 5
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: estimatedDecompressedSize)
        defer { destinationBuffer.deallocate() }
        
        // Decompress the data
        let decompressedSize = compressedData.withUnsafeBytes { sourceBuffer in
            compression_decode_buffer(
                destinationBuffer,
                estimatedDecompressedSize,
                sourceBuffer.bindMemory(to: UInt8.self).baseAddress!,
                compressedData.count,
                nil,
                COMPRESSION_LZFSE
            )
        }
        
        guard decompressedSize > 0 else { return nil }
        
        // Create data from the decompressed buffer
        let decompressedData = Data(bytes: destinationBuffer, count: decompressedSize)
        
        // Convert back to string
        return String(data: decompressedData, encoding: .utf8)
    }
    
    // MARK: - Cleanup and Maintenance
    
    /// Cleans up orphaned image files
    /// - Returns: Number of files removed
    func cleanupOrphanedImageFiles() -> Int {
        // Get all image reference paths from the database
        var imagePaths: [String] = []
        let sql = "SELECT image_reference FROM clipboard_items WHERE image_reference IS NOT NULL;"
        
        let _ = DatabaseManager.shared.query(sql) { statement in
            if let pathCString = sqlite3_column_text(statement, 0) {
                let path = String(cString: pathCString)
                imagePaths.append(path)
            }
        }
        
        // Extract IDs from the paths
        let imageIds = imagePaths.compactMap { path -> String? in
            let filename = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
            return filename
        }
        
        // Clean up orphaned files
        return FileStorageManager.shared.cleanupOrphanedImages(referencedIds: imageIds)
    }
    
    /// Optimizes the database to recover space
    /// - Returns: True if successful
    func optimizeDatabase() -> Bool {
        return DatabaseManager.shared.vacuum()
    }
    
    /// Performs maintenance tasks
    func performMaintenance() {
        processingQueue.async {
            // Clean up old items
            _ = self.cleanupOldItems()
            
            // Clean up orphaned image files
            let removedFiles = self.cleanupOrphanedImageFiles()
            logInfo("Maintenance: Removed \(removedFiles) orphaned image files")
            
            // Optimize database
            if self.optimizeDatabase() {
                logInfo("Maintenance: Database optimized successfully")
            } else {
                logWarning("Maintenance: Database optimization failed")
            }
        }
    }
}
