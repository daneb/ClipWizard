import Foundation
import AppKit
import Combine
import OSLog

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

// Memory pressure management
private var memoryPressureSource: DispatchSourceMemoryPressure?
private var notificationObservers: [NSObjectProtocol] = []
    
    init(sanitizationService: SanitizationService? = nil) {
        self.sanitizationService = sanitizationService
        
        // Load saved clipboard items from persistent storage
        loadSavedHistory()
        
        // Set up memory pressure monitoring
        setupMemoryPressureMonitoring()
        
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
        
        // Remove all notification observers to prevent memory leaks
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
        notificationObservers.removeAll()
        
        // Clean up memory pressure monitoring
        memoryPressureSource?.cancel()
        memoryPressureSource = nil
    }
    
    func startMonitoring() {
        // Don't start if already monitoring
        guard !isMonitoring else { return }
        
        // Check the clipboard every 0.5 seconds
        // Use an autoreleasepool to manage memory more efficiently
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            autoreleasepool {
                self?.checkClipboard()
            }
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
            
            // Perform operations in an autorelease pool for better memory management
            autoreleasepool {
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
                
                // Save the updated history to persistent storage in the background
                DispatchQueue.global(qos: .utility).async { [weak self] in
                    guard let self = self else { return }
                    ClipboardStorageManager.saveClipboardHistory(self.clipboardHistory)
                }
                
                // Post notification that clipboard history has changed
                NotificationCenter.default.post(name: ClipboardMonitor.clipboardHistoryChangedNotification, object: nil)
            }
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
    
    // MARK: - Memory Management
    
    private func setupMemoryPressureMonitoring() {
        // Set up memory pressure monitoring via ProcessInfo
        let memoryStatusObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSProcessInfoPowerStateDidChange, // Use power state as a proxy for system resource monitoring
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Check if we're in a resource-constrained state
            if ProcessInfo.processInfo.isLowPowerModeEnabled {
                self?.handleMemoryWarning()
            }
        }
        notificationObservers.append(memoryStatusObserver)
        
        // Monitor workspace notifications as another proxy
        let workspaceMemoryObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, // System resources might be constrained after wake
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.performMemoryCleanup(level: .warning)
        }
        notificationObservers.append(workspaceMemoryObserver)
        
        // Set up memory pressure source from GCD
        // Note: This is a more direct way to monitor memory pressure on macOS
        let memoryPressureSource = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: DispatchQueue.global(qos: .utility)
        )
        
        memoryPressureSource.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            // Use the source's current event mask to determine the pressure level
            if let currentEvent = getCurrentMemoryPressure() {
                // Handle the pressure based on severity
                if currentEvent == .critical {
                    self.handleMemoryPressure(.critical)
                } else if currentEvent == .warning {
                    self.handleMemoryPressure(.warning)
                }
            }
        }
        
        memoryPressureSource.resume()
        self.memoryPressureSource = memoryPressureSource
    }
    
    private func handleMemoryWarning() {
        logInfo("Received memory warning from the OS")
        performMemoryCleanup(level: .warning)
    }
    
    private func handleMemoryPressure(_ pressureEvent: DispatchSource.MemoryPressureEvent) {
        if pressureEvent == .warning {
            logInfo("Memory pressure: Warning level")
            performMemoryCleanup(level: .warning)
        }
        
        if pressureEvent == .critical {
            logInfo("Memory pressure: Critical level")
            performMemoryCleanup(level: .critical)
        }
    }
    
    private enum MemoryPressureLevel {
        case warning
        case critical
    }
    
    // Helper method to get current memory pressure level
    private func getCurrentMemoryPressure() -> DispatchSource.MemoryPressureEvent? {
        // Check thermal state if available (macOS 10.15+)
        if #available(macOS 10.15, *) {
            switch ProcessInfo.processInfo.thermalState {
            case .critical, .serious:
                return .critical
            case .fair:
                return .warning
            case .nominal:
                return .normal
            @unknown default:
                return .warning
            }
        }
        
        // Default to a warning level if we can't determine
        return .warning
    }
    
    private func performMemoryCleanup(level: MemoryPressureLevel) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            switch level {
            case .warning:
                // Free up non-essential memory
                autoreleasepool {
                    // Release any cached image data that's not currently visible
                    for (index, item) in self.clipboardHistory.enumerated() where item.type == .image {
                        if index > 10 { // Keep first 10 images loaded for quick access
                            item.unloadImage()
                        }
                    }
                }
                
            case .critical:
                // More aggressive memory cleanup
                autoreleasepool {
                    // Unload all image data
                    for item in self.clipboardHistory where item.type == .image {
                        item.unloadImage()
                    }
                    
                    // Trim history if needed
                    let reducedCount = min(self.maxHistoryItems, 50) // Reduce to at most 50 items
                    if self.clipboardHistory.count > reducedCount {
                        self.clipboardHistory = Array(self.clipboardHistory.prefix(reducedCount))
                    }
                }
            }
        }
    }
}
