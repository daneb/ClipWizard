import Foundation
import AppKit
import SwiftUI

/// A manager for persisting clipboard history between app sessions
class ClipboardStorageManager {
    private static let clipboardHistoryKey = "clipwizard.clipboard.history"
    private static let maxPersistedItems = 50
    
    /// Saves the clipboard history to UserDefaults
    /// - Parameter items: Array of ClipboardItem objects to save
    static func saveClipboardHistory(_ items: [ClipboardItem]) {
        logInfo("Saving clipboard history to storage - \(items.count) items")
        
        do {
            // Create a CodableClipboardItem from each ClipboardItem
            let codableItems = items.prefix(maxPersistedItems).map { CodableClipboardItem(from: $0) }
            
            // Encode to data
            let encoder = JSONEncoder()
            let data = try encoder.encode(codableItems)
            
            // Save to UserDefaults
            UserDefaults.standard.set(data, forKey: clipboardHistoryKey)
            logInfo("Successfully saved clipboard history")
        } catch {
            logError("Failed to save clipboard history: \(error.localizedDescription)")
        }
    }
    
    /// Loads the clipboard history from UserDefaults
    /// - Returns: Array of ClipboardItem objects or empty array if none found
    static func loadClipboardHistory() -> [ClipboardItem] {
        logInfo("Loading clipboard history from storage")
        
        guard let data = UserDefaults.standard.data(forKey: clipboardHistoryKey) else {
            logInfo("No saved clipboard history found")
            return []
        }
        
        do {
            // Decode the data
            let decoder = JSONDecoder()
            let codableItems = try decoder.decode([CodableClipboardItem].self, from: data)
            
            // Only use valid items and convert each CodableClipboardItem back to ClipboardItem
            let items = codableItems.filter { $0.isValid() }.compactMap { $0.toClipboardItem() }
            logInfo("Successfully loaded \(items.count) clipboard items from storage")
            
            // If we filtered out any items, log it
            if items.count < codableItems.count {
                logWarning("Filtered out \(codableItems.count - items.count) invalid clipboard items during loading")  
            }
            
            return items
        } catch {
            logError("Failed to load clipboard history: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Clears all saved clipboard history from UserDefaults
    static func clearSavedHistory() {
        UserDefaults.standard.removeObject(forKey: clipboardHistoryKey)
        logInfo("Cleared saved clipboard history")
    }
}

/// A struct version of ClipboardItem that is fully Codable
/// This is used for storage since the main ClipboardItem class has @Published properties
/// and an NSImage property which don't automatically work with Codable
/// Used as an intermediate representation for storage
struct CodableClipboardItem: Codable {
    let timestamp: Date
    let type: ClipboardItemType
    let originalText: String?
    let sanitizedText: String?
    
    // For image type items, we convert the image to a Data representation
    let imageData: Data?
    
    init(from item: ClipboardItem) {
        self.timestamp = item.timestamp
        self.type = item.type
        self.originalText = item.originalText
        self.sanitizedText = item.sanitizedText
        
        // Only handle the image if the type is image
        if item.type == .image, let image = item.originalImage {
            // Convert NSImage to PNG data for storage
            self.imageData = image.pngData()
        } else {
            self.imageData = nil
        }
    }
    
    func toClipboardItem() -> ClipboardItem? {
        switch type {
        case .text:
            guard let text = originalText else { 
                logWarning("Failed to convert CodableClipboardItem to ClipboardItem: Missing originalText")
                return nil 
            }
            let item = ClipboardItem(text: text, timestamp: timestamp)
            item.sanitizedText = sanitizedText
            return item
            
        case .image:
            guard let imgData = imageData else {
                logWarning("Failed to convert CodableClipboardItem to ClipboardItem: Missing imageData")
                return nil 
            }
            guard let image = NSImage(data: imgData) else {
                logWarning("Failed to convert CodableClipboardItem to ClipboardItem: Could not create NSImage from data")
                return nil
            }
            return ClipboardItem(image: image, timestamp: timestamp)
            
        case .unknown:
            logWarning("Cannot convert ClipboardItem of unknown type")
            return nil
        }
    }
}

// Extension to NSImage to convert to PNG data
extension NSImage {
    func pngData() -> Data? {
        guard let tiffRepresentation = tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
}

// Extension to make our CodableClipboardItem more robust
extension CodableClipboardItem {
    // Validate the item before conversion to ensure we don't crash
    func isValid() -> Bool {
        switch type {
        case .text:
            return originalText != nil
        case .image:
            return imageData != nil
        case .unknown:
            return false
        }
    }
}
