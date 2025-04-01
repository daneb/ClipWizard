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
    func setEnabled(_ enabled: Bool) {
        if enabled {
            addToLoginItems()
        } else {
            removeFromLoginItems()
        }
        
        // Store the preference
        UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
    }
    
    /// Toggle launch at login setting
    func toggle() {
        let currentSetting = isEnabled()
        setEnabled(!currentSetting)
    }
    
    /// Add the app to login items using AppleScript
    private func addToLoginItems() {
        guard let appURL = self.appURL else {
            logger.error("Could not get app URL")
            return
        }
        
        let source = """
        tell application "System Events"
            make new login item at end with properties {path:"\(appURL.path)", hidden:false}
        end tell
        """
        
        executeAppleScript(source)
        logger.info("Added app to login items via AppleScript")
    }
    
    /// Remove the app from login items using AppleScript
    private func removeFromLoginItems() {
        guard let appURL = self.appURL else {
            logger.error("Could not get app URL")
            return
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
        
        executeAppleScript(source)
        logger.info("Removed app from login items via AppleScript")
    }
    
    /// Helper method to execute AppleScript
    private func executeAppleScript(_ source: String) {
        var error: NSDictionary?
        if let script = NSAppleScript(source: source) {
            script.executeAndReturnError(&error)
            if let error = error {
                logger.error("AppleScript error: \(error)")
            }
        }
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
        
        var error: NSDictionary?
        if let script = NSAppleScript(source: source) {
            if let result = script.executeAndReturnError(&error).stringValue {
                return result == "true"
            } else if let error = error {
                logger.error("AppleScript error: \(error)")
            }
        }
        
        return false
    }
    
    /// Initialize the service and sync with actual status
    func initialize() {
        // Check actual status and sync with preferences
        let actualStatus = checkIfInLoginItems()
        if isEnabled() != actualStatus {
            UserDefaults.standard.set(actualStatus, forKey: "launchAtLogin")
        }
    }
}
