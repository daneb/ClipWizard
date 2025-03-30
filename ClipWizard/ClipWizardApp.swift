import SwiftUI

@main
struct ClipWizardApp: App {
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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize services
        sanitizationService = SanitizationService()
        sanitizationService?.loadRules()
        
        clipboardMonitor = ClipboardMonitor(sanitizationService: sanitizationService)
        
        // Create the content view
        contentView = ContentView()
        
        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let statusButton = statusItem?.button {
            statusButton.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "ClipWizard")
            statusButton.action = #selector(togglePopover)
        }
        
        // Set up the menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Clipboard History", action: #selector(showHistory), keyEquivalent: "h"))
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About ClipWizard", action: #selector(about), keyEquivalent: "a"))
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
    }
    
    @objc func showHistory() {
        showPopoverWithView(index: 0)
    }
    
    @objc func showSettings() {
        showPopoverWithView(index: 1)
    }
    
    @objc func about() {
        NSApp.orderFrontStandardAboutPanel()
    }
    
    @objc func togglePopover() {
        if let menu = statusItem?.menu {
            statusItem?.button?.performClick(nil)
        } else {
            showPopoverWithView(index: 0)
        }
    }
    
    func showPopoverWithView(index: Int) {
        // Create the popover if it doesn't exist
        if popover == nil {
            let popover = NSPopover()
            popover.behavior = .transient
            popover.contentSize = NSSize(width: 400, height: 400) // Set fixed size for the popover
            self.popover = popover
        }
        
        // Ensure we have a content view
        if contentView == nil {
            contentView = ContentView()
        }
        
        // Create a wrapper view to set the selected tab
        let hostingController = NSHostingController(rootView: 
            contentView!
                .onAppear {
                    // Set the selected tab index
                    if let contentView = self.contentView {
                        // Use reflection to set the selectedTab property
                        if let mirror = Mirror(reflecting: contentView).children.first(where: { $0.label == "_selectedTab" }),
                           let selectedTab = mirror.value as? State<Int> {
                            selectedTab.wrappedValue = index
                        }
                    }
                }
        )
        
        popover?.contentViewController = hostingController
        
        // Show the popover
        if let popover = popover, let button = statusItem?.button {
            if popover.isShown {
                popover.close()
            } else {
                // Ensure the popover appears below the menu bar with enough space
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
                
                // Set the popover position to make sure it's fully visible
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
        }
    }
    
    @objc func quit() {
        NSApp.terminate(nil)
    }
}
