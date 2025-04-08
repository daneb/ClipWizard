# ClipWizard Changelog

## Version 0.2.3 (Current Beta)

### Changes
- Removed "Launch at Login" functionality due to persistent permission issues
- Simplified application startup
- Improved Rules UI with larger display area and better pattern visibility
- Increased popover size for better usability
- Fixed Logs View UI layout issues and improved readability
- Enhanced log content display with text selection support
- Added functional log level filtering in Logs View

## Version 0.2.2

### New Features
- Added comprehensive file-based logging system
- Added logs view in Settings to view application logs
- Added "View Logs" option to the menu bar

### Technical Improvements
- Improved AppleScript operation logging for better diagnostics
- Enhanced logging of permission states for launch-at-login functionality
- Added ability to view and share logs for better troubleshooting
- Maintained AppleScript integration while improving error handling

## Version 0.2.1

### Fixes
- Fixed tab navigation issue where clicking on Settings stayed on History view
- Improved SwiftUI state management for tab selection

### Technical Improvements
- Enhanced ContentView initialization with proper state management
- Restructured popover view creation process to ensure proper tab selection
- Improved the architecture of the app's navigation system

## Version 0.2.0

### New Features
- Enhanced error handling for system integration
- Added user-friendly permission request dialogs
- Improved AppleScript permissions management
- Added proactive permission requesting

### Fixes
- Fixed AppleScript authorization error when interacting with System Events
- Fixed launch-at-login functionality reliability
- Improved entitlements configuration for better system integration
- Added proper error recovery for permission-related issues

### Technical Improvements
- LaunchAtLoginService now properly returns success/failure status
- Added alternative approach hooks for launch-at-login functionality
- Enhanced error handling with descriptive user feedback
- Improved initialization sequence to request permissions early

## Version 0.1.0 (Initial Alpha)

### Features
- Core clipboard monitoring functionality
- Menu bar integration with status item
- Clipboard history with search capability
- Sanitization rules engine
- Multiple sanitization methods (mask, rename, obfuscate, remove)
- Settings panel with tab navigation
- Keyboard shortcut support
- Basic launch-at-login functionality
- Import/export functionality for rules

### Technical Foundation
- ClipboardMonitor service for tracking clipboard changes
- SanitizationService for applying rules to clipboard content
- HotkeyManager for registering global keyboard shortcuts
- User interface with SwiftUI
- Data persistence for clipboard history and settings
