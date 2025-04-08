import Foundation
import AppKit
import os.log

class LaunchAtLoginService {
    static let shared = LaunchAtLoginService()
    
    private let logger = Logger(subsystem: "com.codestrue.ClipWizard", category: "LaunchAtLogin")
    
    // The bundle identifier of our app
    private var bundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? "com.unknown.ClipWizard"
    }
    
    // URL to the app
    private var appURL: URL? {
        return Bundle.main.bundleURL
    }
    
    // URL to the login items folder
    private var loginItemsURL: URL? {
        return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Application Support/com.apple.backgroundtaskmanagementagent/backgrounditems.btm")
    }
    
    private init() {}
    
    /// Check if the app is set to launch at login (stored preference)
    func isEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "launchAtLogin")
    }
    
    /// Enable or disable launch at login using AppleScript
    func setEnabled(_ enabled: Bool) -> Bool {
        let result: Bool
        if enabled {
            result = addToLoginItems()
        } else {
            result = removeFromLoginItems()
        }
        
        // Only store the preference if the operation succeeded
        if result {
            UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
        }
        
        return result
    }
    
    /// Toggle launch at login setting
    func toggle() -> Bool {
        let currentSetting = isEnabled()
        return setEnabled(!currentSetting)
    }
    
    /// Toggle with retry for better permission handling
    func toggleWithRetry() -> Bool {
        let currentSetting = isEnabled()
        let success = setEnabled(!currentSetting)
        
        if !success && !currentSetting {
            // If enabling failed, try again once after a short delay
            // This gives the user time to grant permissions
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else { return }
                _ = self.setEnabled(true)
            }
        }
        
        return success
    }
    
    /// Add the app to login items using AppleScript
    private func addToLoginItems() -> Bool {
        guard let appURL = self.appURL else {
            logger.error("Could not get app URL")
            return false
        }
        
        let source = """
        tell application "System Events"
            make new login item at end with properties {path:"\(appURL.path)", hidden:false}
        end tell
        """
        
        let result = executeAppleScript(source) != nil
        if result {
            logger.info("Added app to login items via AppleScript")
        }
        return result
    }
    
    /// Remove the app from login items using AppleScript
    private func removeFromLoginItems() -> Bool {
        guard let appURL = self.appURL else {
            logger.error("Could not get app URL")
            return false
        }
        
        let source = """
        tell application "System Events"
            set appPath to "\(appURL.path)"
            set loginItems to login items
            repeat with loginItem in loginItems
                if path of loginItem is appPath then
                    delete loginItem
                    exit repeat
                end if
            end repeat
        end tell
        """
        
        let result = executeAppleScript(source) != nil
        if result {
            logger.info("Removed app from login items via AppleScript")
        }
        return result
    }
    
    private func executeAppleScript(_ source: String) -> NSAppleEventDescriptor? {
        var error: NSDictionary?
        if let script = NSAppleScript(source: source) {
            let result = script.executeAndReturnError(&error)
            if let error = error {
                logger.error("AppleScript error: \(error)")
                
                // Check for the permission error code (-1743 is "not authorized")
                if let errorNumber = error[NSAppleScript.errorNumber] as? NSNumber,
                   errorNumber.intValue == -1743 {
                    
                    let alert = NSAlert()
                    alert.messageText = "Permission Required"
                    alert.informativeText = "ClipWizard needs permission to control System Events for launch at login functionality."
                    alert.addButton(withTitle: "Open System Preferences")
                    alert.addButton(withTitle: "Cancel")
                    
                    let response = alert.runModal()
                    if response == .alertFirstButtonReturn {
                        // Open the specific automation section of Privacy & Security
                        if let prefsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                            NSWorkspace.shared.open(prefsURL)
                            
                            // Show follow-up instructions after a delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                let followUpAlert = NSAlert()
                                followUpAlert.messageText = "Complete Permission Setup"
                                followUpAlert.informativeText = "1. In System Preferences, check the box next to System Events for ClipWizard\n2. Return to ClipWizard and try again."
                                followUpAlert.addButton(withTitle: "OK")
                                followUpAlert.runModal()
                            }
                        } else {
                            // Fallback to opening the main Security & Privacy pane
                            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane"))
                        }
                    }
                    
                    return nil
                }
                return nil
            }
            return result
        }
        return nil
    }
    

    /// Check if app is actually in login items using AppleScript
    func checkIfInLoginItems() -> Bool {
        guard let appURL = self.appURL else {
            logger.error("Could not get app URL")
            return false
        }
        
        let source = """
        tell application "System Events"
            set appPath to "\(appURL.path)"
            set loginItemsList to login items
            set isInLoginItems to false
            repeat with loginItem in loginItemsList
                if path of loginItem is appPath then
                    set isInLoginItems to true
                    exit repeat
                end if
            end repeat
            return isInLoginItems
        end tell
        """
        
        if let result = executeAppleScript(source)?.stringValue {
            return result == "true"
        }
        
        return false
    }
    
    /// Initialize the service and sync with actual status
    func initialize() {
        // Check actual status and sync with preferences if possible
        do {
            if let actualStatus = try? checkIfInLoginItems() {
                if isEnabled() != actualStatus {
                    UserDefaults.standard.set(actualStatus, forKey: "launchAtLogin")
                }
            }
        } catch {
            logger.error("Failed to check login items status: \(error)")
        }
    }
    
    /// Alternative method using Service Management framework (more reliable but requires special entitlements)
    func alternativeSetLaunchAtLogin(_ enabled: Bool) -> Bool {
        // This is a fallback method using SMLoginItemSetEnabled if AppleScript fails
        // Note: This requires special entitlements and a helper app
        // Implementation would go here if needed
        return false
    }
}
