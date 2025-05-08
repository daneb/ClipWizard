import SwiftUI
// Import our custom services
import Foundation

@main
struct ClipWizardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Initialize the hotkey manager to ensure it's ready
        _ = HotkeyManager.shared
    }
    
    var body: some Scene {
        // Empty WindowGroup to avoid showing any window when app launches
        // The app only shows in the menu bar
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
    
    // Integration helper
    private let integrationHelper = StorageIntegrationHelper.shared
    
    // Property to hold a reference to the about window controller
    private var aboutWindowController: NSWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize the logging service first, as it's used by other components
        initializeLoggingService()
        logInfo("ClipWizard application starting up")
        
        // Initialize services using the integration helper
        sanitizationService = integrationHelper.getSanitizationService() as? SanitizationService
        clipboardMonitor = integrationHelper.getClipboardMonitor() as? ClipboardMonitor
        
        // Create the content view with default tab (History)
        contentView = integrationHelper.createContentView(initialTab: 0)
        
        // Create the popover
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 450, height: 500)
        self.popover = popover
        
        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let statusButton = statusItem?.button {
            statusButton.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "ClipWizard")
            statusButton.action = #selector(togglePopover)
            statusButton.target = self
            statusButton.sendAction(on: .leftMouseUp) // Ensure action is sent only on left mouse click
            
            // Add tooltip to make it clear what the icon does
            statusButton.toolTip = "ClipWizard - Click to show clipboard history"
            
            // Log that we've set up the status item correctly
            logInfo("Status bar item created and configured")
        }
        
        // Check if we need to show first run info
        checkFirstRunInfo()
        
        // Setup menu items
        statusItem?.menu = NSMenu()
        setupMenu()
        
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
        
        // Launch at Login functionality removed due to permission issues
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
        // If the about window is already open, just bring it to front
        if let windowController = aboutWindowController, windowController.window?.isVisible == true {
            windowController.window?.makeKeyAndOrderFront(nil)
            return
        }
        
        // Create a dedicated About window instead of using the tab system
        let aboutWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 180),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        aboutWindow.center()
        aboutWindow.title = "About ClipWizard"
        
        // Important: Set window to be released when closed
        aboutWindow.isReleasedWhenClosed = false
        
        // Set the window's content view to our SwiftUI AboutWindow view
        let aboutView = AboutWindow()
        let hostingController = NSHostingController(rootView: aboutView)
        aboutWindow.contentViewController = hostingController
        
        // Create a window controller and store it
        let windowController = NSWindowController(window: aboutWindow)
        self.aboutWindowController = windowController
        
        // Set a close delegate to clean up references
        aboutWindow.delegate = self
        
        // Show the window
        windowController.showWindow(nil)
        
        // Log the action
        logInfo("About window displayed")
    }
    
    @objc func togglePopover() {
        if let popover = popover, popover.isShown {
            popover.close()
        } else {
            showPopoverWithView(index: 0) // Show clipboard history when clicking the icon
        }
        
        // Log the action for diagnostics
        logInfo("Menu bar icon clicked, toggling popover")
    }
    
    private func closeMenu() {
        // Close the menu if it's open
        statusItem?.menu?.cancelTracking()
    }
    
    func showPopoverWithView(index: Int) {
        // Log which view we're trying to show
        logInfo("Attempting to show popover with view index: \(index)")
        
        // Create the popover if it doesn't exist
        if popover == nil {
            let popover = NSPopover()
            popover.behavior = .transient
            popover.contentSize = NSSize(width: 450, height: 500) // Set fixed size for the popover
            
            // Add a delegate to handle popover closing
            popover.delegate = self
            
            self.popover = popover
            logInfo("Created new popover instance")
        }
        
        // Create a fresh ContentView with the correct tab selected using the initializer
        do {
            // Ensure our services are initialized through the integration helper
            sanitizationService = integrationHelper.getSanitizationService() as? SanitizationService
            clipboardMonitor = integrationHelper.getClipboardMonitor() as? ClipboardMonitor
            
            // Create the view via integration helper
            self.contentView = integrationHelper.createContentView(initialTab: index)
            
            // Create a hosting controller with the new content view
            if let contentView = self.contentView {
                let hostingController = NSHostingController(rootView: contentView)
                popover?.contentViewController = hostingController
                logInfo("Created hosting controller with content view")
            } else {
                logError("Failed to create content view")
                return
            }
        }
        
        // Show the popover
        if let popover = popover, let button = statusItem?.button {
            // Close menu if it's open
            statusItem?.menu?.cancelTracking()
            
            // Temporarily set menu to nil to prevent it from showing
            let savedMenu = statusItem?.menu
            statusItem?.menu = nil
            
            if popover.isShown {
                popover.close()
                logInfo("Closed existing popover")
            }
            
            // Show the popover anchored correctly to the menu bar item
            // Use minY instead of maxY to ensure it appears below the menu bar
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            logInfo("Showed popover")
            
            // Get the position of the button in screen coordinates
            if let popoverWindow = popover.contentViewController?.view.window {
                let buttonRect = button.convert(button.bounds, to: nil)
                let buttonScreenRect = button.window?.convertToScreen(buttonRect) ?? .zero
                let screenFrame = NSScreen.main?.visibleFrame ?? .zero
                var newFrame = popoverWindow.frame
                
                // Anchor the popover to the button's X position
                newFrame.origin.x = buttonScreenRect.origin.x - (newFrame.width / 2) + (buttonScreenRect.width / 2)
                
                // Position Y coordinate just below the menu bar
                newFrame.origin.y = buttonScreenRect.origin.y - newFrame.height - 5
                
                // Ensure window is not positioned outside screen bounds horizontally
                if newFrame.origin.x < screenFrame.origin.x {
                    newFrame.origin.x = screenFrame.origin.x + 5
                } else if newFrame.origin.x + newFrame.width > screenFrame.origin.x + screenFrame.width {
                    newFrame.origin.x = (screenFrame.origin.x + screenFrame.width) - newFrame.width - 5
                }
                
                // Ensure window is not positioned too low
                if newFrame.origin.y < screenFrame.origin.y {
                    newFrame.origin.y = screenFrame.origin.y + 10
                }
                
                popoverWindow.setFrame(newFrame, display: true)
                logInfo("Adjusted popover position to align with menu bar item")
            }
            
            // Restore the menu after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.statusItem?.menu = savedMenu
                logInfo("Restored status item menu")
            }
        } else {
            logError("Could not show popover - missing popover or status button")
        }
    }
    
    @objc func quit() {
        // Use integration helper to perform proper cleanup
        integrationHelper.performCleanupBeforeTermination()
        
        // SQLite implementation saves automatically
        logInfo("SQLite storage system handles persistence automatically")
        
        // Clean up logging service
        LoggingService.shared.shutdown()
        
        NSApp.terminate(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Use integration helper to perform proper cleanup
        integrationHelper.performCleanupBeforeTermination()
        
        // SQLite implementation handles persistence automatically
        logInfo("SQLite storage system performs automatic cleanup")
        
        // Clean up logging service
        LoggingService.shared.shutdown()
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
        logInfo("Showing clipboard history via keyboard shortcut")
        
        // Always start by ensuring the popover is closed
        if let popover = popover, popover.isShown {
            popover.close()
        }
        
        // Small delay to ensure UI is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.showPopoverWithView(index: 0)
        }
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
        
        // First we need to create or update the content view to show Settings (tab index 1)
        closeMenu()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            // First, create the view with the Settings tab selected
            self.showPopoverWithView(index: 1)
            
            // Now, we need to access the SettingsView and set its tab to Logs
            // We'll use a notification for this since we can't directly access the SettingsView
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                NotificationCenter.default.post(name: .showLogsTab, object: nil)
                logInfo("Posted notification to switch to Logs tab")
            }
        }
    }
}

// MARK: - NSWindowDelegate methods
// MARK: - Helper Methods
extension AppDelegate {
    /// Shows application welcome information if it's the first run
    private func checkFirstRunInfo() {
        // Skip if user has seen the info
        if UserDefaults.standard.bool(forKey: "firstRunInfoShown") {
            return
        }
        
        // Only show after the user has accumulated some clipboard history
        let historyCount = clipboardMonitor?.getHistory().count ?? 0
        if historyCount >= 5 {
            let alert = NSAlert()
            alert.messageText = "Welcome to ClipWizard"
            alert.informativeText = "ClipWizard uses SQLite for efficient storage of your clipboard history. You can customize settings and privacy options in the Settings menu."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Show Settings")
            
            let response = alert.runModal()
            
            if response == .alertSecondButtonReturn { // Show Settings
                // Show the storage settings tab
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.showPopoverWithView(index: 1) // Show Settings
                }
            }
            
            // Mark as shown
            UserDefaults.standard.set(true, forKey: "firstRunInfoShown")
        }
    }

    // Initialize the logging service
    private func initializeLoggingService() {
        // This ensures the LoggingService is ready before any component tries to log
        // The actual implementation might differ based on your LoggingService implementation
        let _ = LoggingService.shared
    }
}

// MARK: - Popover Delegate
extension AppDelegate: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        logInfo("Popover closed")
        
        // Restore menu immediately
        if statusItem?.menu == nil {
            statusItem?.menu = NSMenu()
            setupMenu()
            logInfo("Restored menu after popover close")
        }
    }
    
    // Setup the menu - extracted to a method for reuse
    private func setupMenu() {
        guard let menu = statusItem?.menu else { return }
        
        menu.removeAllItems() // Clear existing items
        
        menu.addItem(NSMenuItem(title: "Show Clipboard History", action: #selector(showHistory), keyEquivalent: "h"))
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About ClipWizard", action: #selector(about), keyEquivalent: "a"))
        menu.addItem(NSMenuItem(title: "View Logs", action: #selector(showLogs), keyEquivalent: "l"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
    }
}

// MARK: - Window Delegate
extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Check if this is our about window
        if let closingWindow = notification.object as? NSWindow,
           let aboutWindow = aboutWindowController?.window,
           closingWindow == aboutWindow {
            // Clean up references
            logInfo("About window closing, cleaning up references")
            aboutWindowController = nil
        }
    }
}
