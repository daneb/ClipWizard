import Foundation
import AppKit
import ObjectiveC

/// Helper class for storage and privacy features
class StorageIntegrationHelper {
    /// Singleton instance
    static let shared = StorageIntegrationHelper()
    
    // SQLite-based services
    private lazy var sanitizationService: EnhancedSanitizationService = {
        return EnhancedSanitizationService()
    }()
    
    private lazy var clipboardMonitor: EnhancedClipboardMonitor = {
        return EnhancedClipboardMonitor(sanitizationService: sanitizationService)
    }()
    
    private init() {
        // Make sure we set a flag indicating we're using the SQLite storage
        UserDefaults.standard.set(true, forKey: "useEnhancedStorage")
    }
    
    /// Get the sanitization service
    func getSanitizationService() -> Any {
        return sanitizationService
    }
    
    /// Get the clipboard monitor
    func getClipboardMonitor() -> Any {
        return clipboardMonitor
    }
    

    
    /// Create a ContentView with the SQLite-based services
    func createContentView(initialTab: Int = 0) -> ContentView {
        // Create the ContentView using the SQLite implementation with bridge for compatibility
        return ContentView(
            sanitizationService: EnhancedImplementationBridge.createBridgedSanitizationService(sanitizationService),
            clipboardMonitor: EnhancedImplementationBridge.createBridgedClipboardMonitor(clipboardMonitor),
            initialTab: initialTab
        )
    }
    
    /// Perform cleanup when the application is about to terminate
    func performCleanupBeforeTermination() {
        clipboardMonitor.performMaintenance()
    }
}

/// Bridging class to make the enhanced implementation compatible with the original interfaces
class EnhancedImplementationBridge {
    // Keep track of our notification observers to prevent dangling references
    private static var observers: [NSObjectProtocol] = []
    
    /// Create a SanitizationService that wraps an EnhancedSanitizationService
    static func createBridgedSanitizationService(_ enhancedService: EnhancedSanitizationService) -> SanitizationService {
        let bridge = SanitizationService()
        
        // Copy rules from the enhanced service to the bridge
        bridge.rules = enhancedService.rules
        
        return bridge
    }
    
    /// Create a ClipboardMonitor that wraps an EnhancedClipboardMonitor
    static func createBridgedClipboardMonitor(_ enhancedMonitor: EnhancedClipboardMonitor) -> ClipboardMonitor {
        let bridge = ClipboardMonitor()
        
        // Create strong reference to the enhanced monitor
        objc_setAssociatedObject(bridge, "enhancedMonitor", enhancedMonitor, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Initialize clipboard history in the bridge
        bridge.clipboardHistory = enhancedMonitor.clipboardHistory
        
        // Remove any previous observers to prevent duplicates and memory issues
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
        
        // Create a new observer with proper memory management
        let observer = NotificationCenter.default.addObserver(
            forName: EnhancedClipboardMonitor.clipboardHistoryChangedNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Store a strong reference to the enhanced monitor to avoid it being deallocated
            let enhancedMonitorRef = objc_getAssociatedObject(bridge, "enhancedMonitor") as? EnhancedClipboardMonitor
            if let monitor = enhancedMonitorRef {
                // Update the bridge's history from the referenced monitor
                bridge.clipboardHistory = monitor.clipboardHistory
                
                // Post notification for anything observing the bridge
                NotificationCenter.default.post(name: ClipboardMonitor.clipboardHistoryChangedNotification, object: nil)
            }
        }
        
        // Store the observer so we can clean it up later
        observers.append(observer)
        
        return bridge
    }
}

// MARK: - Extensions
