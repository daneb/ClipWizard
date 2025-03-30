import Foundation
import SwiftUI

enum ClipboardItemType {
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
    }
}

extension ClipboardItem: Equatable {
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.id == rhs.id
    }
}
