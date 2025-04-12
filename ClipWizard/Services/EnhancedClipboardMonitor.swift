import Foundation
import AppKit
import Combine

class EnhancedClipboardMonitor: ObservableObject {
    // Notification that gets posted whenever the clipboard history changes
    static let clipboardHistoryChangedNotification = Notification.Name("clipboardHistoryChangedNotification")
    
    @Published var clipboardHistory: [ClipboardItem] = []
    @Published private(set) var isMonitoring: Bool = false
    
    private var maxHistoryItems = 100
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount
    
    // Enhanced services
    private var sanitizationService: EnhancedSanitizationService?
    let storageManager = EnhancedClipboardStorageManager.shared
    
    // Settings
    private var monitoringInterval: TimeInterval = 0.5
    private var automaticCleanupInterval: TimeInterval = 3600 // 1 hour
    private var lastCleanupTime = Date()
    
    init(sanitizationService: EnhancedSanitizationService? = nil) {
        self.sanitizationService = sanitizationService
        
        // Load saved clipboard items
        loadSavedHistory()
        
        // Start monitoring the clipboard
        startMonitoring()
        
        // Schedule automatic maintenance
        scheduleAutomaticMaintenance()
    }
    
    private func loadSavedHistory() {
        // Load from the enhanced storage manager with a reasonable limit
        let savedItems = storageManager.loadClipboardHistory(limit: maxHistoryItems)
        
        // Only use the loaded items if we have any
        if !savedItems.isEmpty {
            // Update each item to have a reference to this monitor
            savedItems.forEach { $0.typeErasedClipboardMonitor = self }
            
            // Set the history to the loaded items
            clipboardHistory = savedItems
            
            logInfo("Loaded \(savedItems.count) clipboard items from database")
        }
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        // Don't start if already monitoring
        guard !isMonitoring else { return }
        
        // Check the clipboard at the specified interval
        timer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        
        isMonitoring = true
        logInfo("Started clipboard monitoring")
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
        logInfo("Stopped clipboard monitoring")
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        // Only process if the pasteboard has changed
        guard currentChangeCount != lastChangeCount else { return }
        
        lastChangeCount = currentChangeCount
        
        // Process text content
        if let clipboardString = pasteboard.string(forType: .string) {
            let newItem = ClipboardItem(text: clipboardString)
            newItem.typeErasedClipboardMonitor = self
            
            // Apply sanitization if the service is available
            if let sanitizationService = sanitizationService {
                newItem.sanitizedText = sanitizationService.sanitize(text: clipboardString)
            }
            
            addItemToHistory(newItem)
        }
        // Process image content
        else if let clipboardImage = pasteboard.data(forType: .tiff).flatMap({ NSImage(data: $0) }) {
            let newItem = ClipboardItem(image: clipboardImage)
            newItem.typeErasedClipboardMonitor = self
            
            // Check for sensitive data in images if service is available
            if let sanitizationService = sanitizationService {
                _ = sanitizationService.processImageForSensitiveText(newItem)
            }
            
            addItemToHistory(newItem)
        }
    }
    
    private func addItemToHistory(_ item: ClipboardItem) {
        // Add to the beginning of the array to show most recent first
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Check if we already have this item to avoid duplicates
            // For text items, compare the text content
            if item.type == .text, 
               let text = item.originalText,
               self.clipboardHistory.contains(where: { $0.originalText == text }) {
                return
            }
            
            // Add the new item at the beginning
            self.clipboardHistory.insert(item, at: 0)
            
            // Trim history if it exceeds the maximum size
            if self.clipboardHistory.count > self.maxHistoryItems {
                self.clipboardHistory = Array(self.clipboardHistory.prefix(self.maxHistoryItems))
            }
            
            // Save the item to the database
            _ = self.storageManager.saveClipboardItem(item)
            
            // Post notification that clipboard history has changed
            NotificationCenter.default.post(name: Self.clipboardHistoryChangedNotification, object: nil)
        }
    }
    
    func clearHistory() {
        clipboardHistory.removeAll()
        
        // Clear the database
        _ = storageManager.clearClipboardHistory()
        
        // Post notification that clipboard history has changed
        NotificationCenter.default.post(name: Self.clipboardHistoryChangedNotification, object: nil)
        
        logInfo("Clipboard history cleared")
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.type {
        case .text:
            if let text = item.sanitizedText ?? item.originalText {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let image = item.originalImage, 
               let tiffData = image.tiffRepresentation {
                pasteboard.setData(tiffData, forType: .tiff)
            }
        case .unknown:
            break
        }
    }
    
    func setMaxHistoryItems(_ max: Int) {
        maxHistoryItems = max
        
        // Trim history if needed
        if clipboardHistory.count > maxHistoryItems {
            clipboardHistory = Array(clipboardHistory.prefix(maxHistoryItems))
        }
        
        // Trigger a cleanup in the database
        storageManager.cleanupOldItems()
    }
    
    func getHistory(searchText: String? = nil, limit: Int = 100) -> [ClipboardItem] {
        if let searchText = searchText, !searchText.isEmpty {
            // If searching, load from database to include items not in memory
            return storageManager.loadClipboardHistory(limit: limit, searchText: searchText)
        } else if limit == maxHistoryItems {
            // If requesting all items with default limit, use in-memory list
            return clipboardHistory
        } else {
            // Otherwise, get from database with the specified limit
            return storageManager.loadClipboardHistory(limit: limit)
        }
    }
    
    func deleteItem(_ item: ClipboardItem) {
        // Remove from in-memory array
        if let index = clipboardHistory.firstIndex(where: { $0.id == item.id }) {
            clipboardHistory.remove(at: index)
        }
        
        // Remove from database
        _ = storageManager.deleteClipboardItem(item)
        
        // Post notification
        NotificationCenter.default.post(name: Self.clipboardHistoryChangedNotification, object: nil)
    }
    
    // MARK: - Maintenance Functions
    
    private func scheduleAutomaticMaintenance() {
        // Schedule maintenance every hour
        Timer.scheduledTimer(withTimeInterval: automaticCleanupInterval, repeats: true) { [weak self] _ in
            self?.performMaintenance()
        }
    }
    
    func performMaintenance() {
        // Run maintenance in the background
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            // Clean up old items beyond the retention period 
            let retentionPeriod = UserDefaults.standard.integer(forKey: "clipboardRetentionPeriodHours")
            
            if retentionPeriod > 0 {
                let cutoffDate = Date().addingTimeInterval(-Double(retentionPeriod * 3600))
                _ = self.storageManager.cleanupOldItems(olderThan: cutoffDate)
            }
            
            // Run storage manager maintenance
            self.storageManager.performMaintenance()
            
            // Update last cleanup time
            self.lastCleanupTime = Date()
            
            logInfo("Automatic maintenance completed")
        }
    }
    
    // MARK: - Settings
    
    func setMonitoringInterval(_ interval: TimeInterval) {
        monitoringInterval = interval
        
        // Restart monitoring with the new interval
        if isMonitoring {
            stopMonitoring()
            startMonitoring()
        }
    }
    
    func setAutomaticCleanupInterval(_ interval: TimeInterval) {
        automaticCleanupInterval = interval
    }
    
    // MARK: - Statistics
    
    func getStorageStatistics() -> [String: Any] {
        let totalItems = storageManager.countClipboardItems()
        let textItems = storageManager.countClipboardItems(searchText: "content_type = 'text'")
        let imageItems = storageManager.countClipboardItems(searchText: "content_type = 'image'")
        
        return [
            "totalItems": totalItems,
            "textItems": textItems,
            "imageItems": imageItems,
            "lastCleanupTime": lastCleanupTime
        ]
    }
}
