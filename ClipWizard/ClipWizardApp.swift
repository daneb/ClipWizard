import SwiftUI
// Import our custom services
import Foundation

@main
struct ClipWizardApp: App {
    init() {
        // Initialize the hotkey manager to ensure it's ready
        _ = HotkeyManager.shared
    }
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var contentView: ContentView?
    var sanitizationService: SanitizationService?
    var clipboardMonitor: ClipboardMonitor?
    var hotkeyManager: HotkeyManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize the logging service
        logInfo("ClipWizard application starting up")
        
        // Initialize services
        sanitizationService = SanitizationService()
        sanitizationService?.loadRules()
        
        clipboardMonitor = ClipboardMonitor(sanitizationService: sanitizationService)
        
        // Create the content view with default tab (History)
        contentView = ContentView(sanitizationService: sanitizationService!, clipboardMonitor: clipboardMonitor!, initialTab: 0)
        
        // Create the popover
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 400, height: 400)
        self.popover = popover
        
        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let statusButton = statusItem?.button {
            statusButton.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "ClipWizard")
            statusButton.action = #selector(togglePopover)
            statusButton.target = self
        }
        
        // Set up the menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Clipboard History", action: #selector(showHistory), keyEquivalent: "h"))
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About ClipWizard", action: #selector(about), keyEquivalent: "a"))
        menu.addItem(NSMenuItem(title: "View Logs", action: #selector(showLogs), keyEquivalent: "l"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        
        // Check if we should start monitoring based on user preferences
        let shouldMonitor = UserDefaults.standard.bool(forKey: "monitoringEnabled")
        if shouldMonitor {
            clipboardMonitor?.startMonitoring()
        } else {
            // Default to true if preference not set
            clipboardMonitor?.startMonitoring()
            UserDefaults.standard.set(true, forKey: "monitoringEnabled")
        }
        
        // Set the max history items from user preferences
        let maxItems = UserDefaults.standard.integer(forKey: "maxHistoryItems")
        if maxItems > 0 {
            clipboardMonitor?.setMaxHistoryItems(maxItems)
        }
        
        // Initialize and load the hotkey manager
        hotkeyManager = HotkeyManager.shared
        setupHotkeyNotifications()
        hotkeyManager?.loadHotkeys()
        
        // Initialize launch at login service
        LaunchAtLoginService.shared.initialize()
    }
    
    @objc func showHistory() {
        closeMenu()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.showPopoverWithView(index: 0)
        }
    }
    
    @objc func showSettings() {
        closeMenu()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.showPopoverWithView(index: 1)
        }
    }
    
    @objc func about() {
        NSApp.orderFrontStandardAboutPanel()
    }
    
    @objc func togglePopover() {
        if let popover = popover, popover.isShown {
            popover.close()
        } else {
            showPopoverWithView(index: 0)
        }
    }
    
    private func closeMenu() {
        // Close the menu if it's open
        statusItem?.menu?.cancelTracking()
    }
    
    func showPopoverWithView(index: Int) {
        // Create the popover if it doesn't exist
        if popover == nil {
            let popover = NSPopover()
            popover.behavior = .transient
            popover.contentSize = NSSize(width: 400, height: 400) // Set fixed size for the popover
            self.popover = popover
        }
        
        // Create a fresh ContentView with the correct tab selected using the initializer
        self.contentView = ContentView(
            sanitizationService: sanitizationService!, 
            clipboardMonitor: clipboardMonitor!,
            initialTab: index
        )
        
        // Create a hosting controller with the new content view
        let hostingController = NSHostingController(rootView: self.contentView!)
        popover?.contentViewController = hostingController
        
        // Show the popover
        if let popover = popover, let button = statusItem?.button {
            // Close menu if it's open
            statusItem?.menu?.cancelTracking()
            
            // Temporarily set menu to nil to prevent it from showing
            let savedMenu = statusItem?.menu
            statusItem?.menu = nil
            
            if popover.isShown {
                popover.close()
            } else {
                // Show the popover
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
                
                // Position the popover properly
                if let popoverWindow = popover.contentViewController?.view.window {
                    let screenFrame = NSScreen.main?.visibleFrame ?? .zero
                    var newFrame = popoverWindow.frame
                    
                    // Ensure window is not positioned too high
                    if newFrame.origin.y + newFrame.height > screenFrame.height {
                        newFrame.origin.y = screenFrame.height - newFrame.height - 10
                    }
                    
                    // Ensure window is not positioned too low
                    if newFrame.origin.y < screenFrame.origin.y {
                        newFrame.origin.y = screenFrame.origin.y + 10
                    }
                    
                    popoverWindow.setFrame(newFrame, display: true)
                }
            }
            
            // Restore the menu after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.statusItem?.menu = savedMenu
            }
        }
    }
    
    @objc func quit() {
        NSApp.terminate(nil)
    }
    
    // Setup hotkey notification handlers
    func setupHotkeyNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowClipboardHistory),
            name: .showClipboardHistory,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleToggleClipboardMonitoring),
            name: .toggleClipboardMonitoring,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClearClipboardHistory),
            name: .clearClipboardHistory,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCopyLastClipboardItem),
            name: .copyLastClipboardItem,
            object: nil
        )
    }
    
    @objc func handleShowClipboardHistory() {
        showPopoverWithView(index: 0)
    }
    
    @objc func handleToggleClipboardMonitoring() {
        if clipboardMonitor?.isMonitoring ?? false {
            clipboardMonitor?.stopMonitoring()
        } else {
            clipboardMonitor?.startMonitoring()
        }
    }
    
    @objc func handleClearClipboardHistory() {
        clipboardMonitor?.clearHistory()
    }
    
    @objc func handleCopyLastClipboardItem() {
        if let lastItem = clipboardMonitor?.getHistory().first {
            clipboardMonitor?.copyToClipboard(lastItem)
        }
    }
    
    // Show application logs
    @objc func showLogs() {
        logInfo("User requested to view application logs")
        
        if let logPath = LoggingService.shared.getLogFilePath() {
            // Try to open the log file in Console.app or a text editor
            NSWorkspace.shared.open(URL(fileURLWithPath: logPath))
        } else {
            // Show an error if we couldn't get the log path
            let alert = NSAlert()
            alert.messageText = "Cannot Access Logs"
            alert.informativeText = "Unable to access the application logs. Please check application permissions."
            alert.runModal()
        }
    }
}
