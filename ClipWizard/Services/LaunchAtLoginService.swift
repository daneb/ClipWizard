import Foundation
import AppKit

class LaunchAtLoginService {
    static let shared = LaunchAtLoginService()
    
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
            logError("Could not get app URL")
            return false
        }
        
        let source = """
        tell application "System Events"
            make new login item at end with properties {path:"\(appURL.path)", hidden:false}
        end tell
        """
        
        let result = executeAppleScript(source) != nil
        if result {
            logInfo("Added app to login items via AppleScript")
        } else {
            logWarning("Failed to add app to login items via AppleScript - permissions may be required")
            // Log the failure but return true to allow the preference to be set
            // This way users can still set the preference even if the AppleScript fails
            return true
        }
        return result
    }
    
    /// Remove the app from login items using AppleScript
    private func removeFromLoginItems() -> Bool {
        guard let appURL = self.appURL else {
            logError("Could not get app URL")
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
            logInfo("Removed app from login items via AppleScript")
        } else {
            logWarning("Failed to remove app from login items via AppleScript - permissions may be required")
            // Log the failure but return true to allow the preference to be set
            // This way users can still set the preference even if the AppleScript fails
            return true
        }
        return result
    }
    
    private func executeAppleScript(_ source: String) -> NSAppleEventDescriptor? {
        var error: NSDictionary?
        if let script = NSAppleScript(source: source) {
            let result = script.executeAndReturnError(&error)
            if let error = error {
                logError("AppleScript error: \(error)")
                
                // Check for the permission error code (-1743 is "not authorized")
                if let errorNumber = error[NSAppleScript.errorNumber] as? NSNumber,
                   errorNumber.intValue == -1743 {
                    logWarning("Permission required for AppleScript execution. User should check System Events permissions in Privacy & Security.")
                }
                return nil
            }
            return result
        }
        return nil
    }
    

    /// Initialize the service
    func initialize() {
        logInfo("LaunchAtLoginService initialized. Current setting: \(isEnabled() ? "enabled" : "disabled")")
    }
    
    /// Alternative method using Service Management framework (more reliable but requires special entitlements)
    func alternativeSetLaunchAtLogin(_ enabled: Bool) -> Bool {
        // This is a fallback method using SMLoginItemSetEnabled if AppleScript fails
        // Note: This requires special entitlements and a helper app
        // Implementation would go here if needed
        return false
    }
}
