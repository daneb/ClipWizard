import Foundation
import AppKit
import CryptoKit

/// Manages the storage and retrieval of files, primarily clipboard images
class FileStorageManager {
    static let shared = FileStorageManager()
    
    // Directory for storing clipboard images
    private let imagesDirectory: URL
    
    // Storage encryption key
    private var encryptionKey: SymmetricKey?
    
    // Queue for file operations
    private let fileQueue = DispatchQueue(label: "com.clipwizard.filestorage", qos: .background)
    
    private init() {
        // Create a directory for our app data if it doesn't exist
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirURL = appSupportURL.appendingPathComponent("ClipWizard", isDirectory: true)
        
        // Create images directory
        imagesDirectory = appDirURL.appendingPathComponent("Images", isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            logInfo("Successfully created images directory at: \(imagesDirectory.path)")
        } catch {
            logError("Failed to create images directory: \(error.localizedDescription)")
        }
        
        // Initialize or load encryption key
        initializeEncryption()
    }
    
    /// Initialize encryption for file storage
    private func initializeEncryption() {
        // Check if we have a stored key
        if let keyData = KeychainManager.loadData(service: "com.clipwizard.filestorage", account: "encryptionKey") {
            self.encryptionKey = SymmetricKey(data: keyData)
            logInfo("Loaded existing encryption key")
        } else {
            // Generate a new encryption key
            let newKey = SymmetricKey(size: .bits256)
            let keyData = newKey.withUnsafeBytes { Data($0) }
            
            // Save the key to the keychain
            if KeychainManager.saveData(keyData, service: "com.clipwizard.filestorage", account: "encryptionKey") {
                self.encryptionKey = newKey
                logInfo("Generated and stored new encryption key")
            } else {
                logError("Failed to store encryption key")
                // Fall back to a derived key if keychain fails
                self.encryptionKey = generateDerivedKey()
            }
        }
    }
    
    /// Generate a key derived from device information as fallback
    private func generateDerivedKey() -> SymmetricKey {
        // Use device and user information as seed
        let hostName = ProcessInfo.processInfo.hostName
        let userName = NSUserName()
        let seed = "\(hostName):\(userName):ClipWizardEncryption"
        
        // Hash the seed to create a consistent key
        let seedData = Data(seed.utf8)
        let hashedData = SHA256.hash(data: seedData)
        return SymmetricKey(data: hashedData)
    }
    
    /// Saves an image to the file system
    /// - Parameters:
    ///   - image: The NSImage to save
    ///   - id: The unique ID to use for the filename
    /// - Returns: The reference path if successful, nil otherwise
    func saveImage(_ image: NSImage, withId id: String) -> String? {
        return fileQueue.sync {
            guard let imageData = image.pngData() else {
                logError("Failed to convert image to PNG data")
                return nil
            }
            
            // Compress the image if it's too large
            let compressedData: Data
            if imageData.count > 1_000_000 { // 1MB
                if let jpegData = image.jpegData(compressionQuality: 0.7) {
                    compressedData = jpegData
                } else {
                    compressedData = imageData
                }
            } else {
                compressedData = imageData
            }
            
            // Encrypt the data if encryption is enabled
            let dataToSave: Data
            if let key = encryptionKey {
                do {
                    let sealedBox = try AES.GCM.seal(compressedData, using: key)
                    if let combinedData = sealedBox.combined {
                        dataToSave = combinedData
                    } else {
                        logError("Failed to combine encrypted data")
                        dataToSave = compressedData
                    }
                } catch {
                    logError("Image encryption failed: \(error.localizedDescription)")
                    dataToSave = compressedData
                }
            } else {
                dataToSave = compressedData
            }
            
            // Generate the file path
            let filePath = imagesDirectory.appendingPathComponent("\(id).bin")
            
            do {
                try dataToSave.write(to: filePath)
                logInfo("Saved image to \(filePath.path)")
                return filePath.path
            } catch {
                logError("Failed to save image: \(error.localizedDescription)")
                return nil
            }
        }
    }
    
    /// Loads an image from the file system
    /// - Parameter id: The unique ID of the image
    /// - Returns: The NSImage if successful, nil otherwise
    func loadImage(withId id: String) -> NSImage? {
        return fileQueue.sync {
            let filePath = imagesDirectory.appendingPathComponent("\(id).bin")
            
            guard let encryptedData = try? Data(contentsOf: filePath) else {
                logError("Failed to load image data from \(filePath.path)")
                return nil
            }
            
            // Decrypt the data if encryption is enabled
            let imageData: Data
            if let key = encryptionKey {
                do {
                    let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
                    imageData = try AES.GCM.open(sealedBox, using: key)
                } catch {
                    logError("Image decryption failed: \(error.localizedDescription)")
                    // Try to use the data directly as fallback
                    imageData = encryptedData
                }
            } else {
                imageData = encryptedData
            }
            
            // Try to create an image from the data
            if let image = NSImage(data: imageData) {
                return image
            }
            
            logError("Failed to create image from data")
            return nil
        }
    }
    
    /// Deletes an image from the file system
    /// - Parameter id: The unique ID of the image
    /// - Returns: True if successful, false otherwise
    func deleteImage(withId id: String) -> Bool {
        return fileQueue.sync {
            let filePath = imagesDirectory.appendingPathComponent("\(id).bin")
            
            // Securely delete by overwriting with random data first
            let fileSize = try? FileManager.default.attributesOfItem(atPath: filePath.path)[.size] as? Int
            if let size = fileSize, size > 0 {
                securelyDeleteFile(at: filePath, size: size)
            }
            
            // Then actually delete the file
            do {
                try FileManager.default.removeItem(at: filePath)
                logInfo("Deleted image at \(filePath.path)")
                return true
            } catch {
                if !FileManager.default.fileExists(atPath: filePath.path) {
                    // File already doesn't exist, consider this a success
                    return true
                }
                logError("Failed to delete image: \(error.localizedDescription)")
                return false
            }
        }
    }
    
    /// Securely deletes a file by overwriting it with random data
    /// - Parameters:
    ///   - url: The URL of the file to delete
    ///   - size: The size of the file
    private func securelyDeleteFile(at url: URL, size: Int) {
        // Open the file for writing
        guard let fileHandle = try? FileHandle(forWritingTo: url) else {
            logError("Could not open file for secure deletion: \(url.path)")
            return
        }
        
        // Generate random data to overwrite the file
        var randomData = Data(count: min(size, 1024 * 1024)) // 1MB chunks max
        _ = randomData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, $0.count, $0.baseAddress!)
        }
        
        // Overwrite the file with random data
        do {
            let chunkSize = randomData.count
            let chunks = (size + chunkSize - 1) / chunkSize
            
            for _ in 0..<chunks {
                try fileHandle.write(contentsOf: randomData)
            }
            
            try fileHandle.synchronize() // Ensure data is written to disk
            try fileHandle.close()
        } catch {
            logError("Error during secure file deletion: \(error.localizedDescription)")
            try? fileHandle.close()
        }
    }
    
    /// Deletes all images from the file system
    /// - Returns: True if successful, false otherwise
    func deleteAllImages() -> Bool {
        return fileQueue.sync {
            do {
                let fileManager = FileManager.default
                let fileURLs = try fileManager.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: nil)
                
                for fileURL in fileURLs {
                    // Get file size for secure deletion
                    let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                    if let fileSize = attributes[.size] as? Int, fileSize > 0 {
                        securelyDeleteFile(at: fileURL, size: fileSize)
                    }
                    
                    // Delete the file
                    try fileManager.removeItem(at: fileURL)
                }
                
                logInfo("Successfully deleted all images")
                return true
            } catch {
                logError("Failed to delete all images: \(error.localizedDescription)")
                return false
            }
        }
    }
    
    /// Cleans up orphaned image files that are not referenced in the database
    /// - Parameter referencedIds: Array of image IDs that are still referenced
    /// - Returns: Number of orphaned files removed
    func cleanupOrphanedImages(referencedIds: [String]) -> Int {
        return fileQueue.sync {
            var removedCount = 0
            
            do {
                let fileManager = FileManager.default
                let fileURLs = try fileManager.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: nil)
                
                for fileURL in fileURLs {
                    // Extract the ID from the filename (remove extension)
                    let filename = fileURL.deletingPathExtension().lastPathComponent
                    
                    // If this ID is not in the referenced list, delete it
                    if !referencedIds.contains(filename) {
                        try fileManager.removeItem(at: fileURL)
                        removedCount += 1
                    }
                }
                
                logInfo("Cleaned up \(removedCount) orphaned image files")
            } catch {
                logError("Failed to cleanup orphaned images: \(error.localizedDescription)")
            }
            
            return removedCount
        }
    }
}

// MARK: - KeychainManager

/// Simple manager for Keychain operations
class KeychainManager {
    static func saveData(_ data: Data, service: String, account: String) -> Bool {
        // Create query for the keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    static func loadData(service: String, account: String) -> Data? {
        // Create query for the keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        } else {
            return nil
        }
    }
}

// MARK: - NSImage Extensions

extension NSImage {
    /// Converts the image to JPEG data with the specified compression quality
    /// - Parameter compressionQuality: The compression quality (0.0 to 1.0)
    /// - Returns: The JPEG data, or nil if conversion fails
    func jpegData(compressionQuality: CGFloat = 0.8) -> Data? {
        guard let tiffRepresentation = tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        
        return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }
}
