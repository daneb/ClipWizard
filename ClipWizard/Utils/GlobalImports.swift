import Foundation
import SwiftUI
import AppKit
import Combine
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers

// Add global logging function for convenience
func logInfo(_ message: String) {
    // Forward to the existing logging service if available
    NotificationCenter.default.post(
        name: Notification.Name("LogMessage"),
        object: nil,
        userInfo: ["level": "INFO", "message": message]
    )
    
    // Also print to console during development
    print("[INFO] \(message)")
}

func logError(_ message: String) {
    // Forward to the existing logging service if available
    NotificationCenter.default.post(
        name: Notification.Name("LogMessage"),
        object: nil,
        userInfo: ["level": "ERROR", "message": message]
    )
    
    // Also print to console during development
    print("[ERROR] \(message)")
}

func logWarning(_ message: String) {
    // Forward to the existing logging service if available
    NotificationCenter.default.post(
        name: Notification.Name("LogMessage"),
        object: nil,
        userInfo: ["level": "WARNING", "message": message]
    )
    
    // Also print to console during development
    print("[WARNING] \(message)")
}
