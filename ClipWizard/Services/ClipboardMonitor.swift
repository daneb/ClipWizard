import Foundation
import AppKit
import Combine

class ClipboardMonitor: ObservableObject {
    // Notification that gets posted whenever the clipboard history changes
    static let clipboardHistoryChangedNotification = Notification.Name("clipboardHistoryChangedNotification")
    @Published var clipboardHistory: [ClipboardItem] = []
    @Published private(set) var isMonitoring: Bool = false
    private var maxHistoryItems = 50
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var sanitizationService: SanitizationService?
    
    init(sanitizationService: SanitizationService? = nil) {
        self.sanitizationService = sanitizationService
        
        // Load saved clipboard items from persistent storage
        loadSavedHistory()
        
        startMonitoring()
    }
    
    private func loadSavedHistory() {
        // Load clipboard history from persistent storage
        let savedItems = ClipboardStorageManager.loadClipboardHistory()
        
        // Only use the loaded items if we have any
        if !savedItems.isEmpty {
            // Update each item to have a reference to this monitor
            savedItems.forEach { $0.typeErasedClipboardMonitor = self }
            
            // Set the history to the loaded items
            clipboardHistory = savedItems
            
            logInfo("Loaded \(savedItems.count) clipboard items from persistent storage")
        }
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        // Don't start if already monitoring
        guard !isMonitoring else { return }
        
        // Check the clipboard every 0.5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        
        isMonitoring = true
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
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
            
            // Save the updated history to persistent storage
            ClipboardStorageManager.saveClipboardHistory(self.clipboardHistory)
            
            // Post notification that clipboard history has changed
            NotificationCenter.default.post(name: ClipboardMonitor.clipboardHistoryChangedNotification, object: nil)
        }
    }
    
    func clearHistory() {
        clipboardHistory.removeAll()
        
        // Clear the persistent storage as well
        ClipboardStorageManager.clearSavedHistory()
        
        // Post notification that clipboard history has changed
        NotificationCenter.default.post(name: ClipboardMonitor.clipboardHistoryChangedNotification, object: nil)
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
            
            // Save the updated (trimmed) history
            ClipboardStorageManager.saveClipboardHistory(clipboardHistory)
        }
    }
    
    func getHistory() -> [ClipboardItem] {
        return clipboardHistory
    }
}
