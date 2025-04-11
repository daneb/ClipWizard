# ClipWizard Changelog

## Version 0.4.0 (April 2025 Update)

### Fixes

- Fixed major popover positioning issue:
  - Resolved inconsistent window positioning when installed via DMG to Applications folder
  - Simplified window positioning logic by relying on macOS native positioning
  - Removed manual positioning calculations that caused rendering issues
  - Improved menu bar popover reliability and consistency across different environments
  - Enhanced the user experience with more predictable UI behavior

## Version 0.3.0

### Fixes

- Fixed popover positioning issue:
  - Corrected the positioning of the clipboard history popover to properly align with the menu bar icon
  - Improved popup positioning when activated via keyboard shortcuts
  - Enhanced window positioning to prevent off-screen rendering
  - Added proper event handling when popover closes
  - Fixed menu restoration after popover closure
  - Added X-coordinate adjustment to center the popover under the menu bar icon

## Version 0.2.9

### Fixes

- Fixed OCR text copying functionality:
  - Added text selection capability to OCR text display
  - Added dedicated "Copy OCR Text" button
  - Improved OCR text display with monospace font and better formatting
  - Limited display to 500 lines with option to copy full text
  - Improved text extraction by preserving layout with line breaks
  - Enhanced visual design of OCR text area

## Version 0.2.8

### Technical Improvements

- Major code refactoring to improve maintainability:
  - Decomposed large ClipboardHistoryView file into smaller, focused components
  - Created dedicated component files for ClipboardItemRow, ImagePreviewOverlay, and ClipboardItemDetailView
  - Extracted image processing logic into centralized ImageProcessingHelpers utility
  - Added UI extensions in separate files for better code organization
  - Improved overall code structure with better separation of concerns
  - Enhanced file organization with logical directory structure

### Benefits

- Improved code maintainability and readability
- Reduced file sizes for easier navigation
- Better component isolation for future enhancements
- No functionality changes or regressions

## Version 0.2.7

### New Features

- Enhanced image handling with advanced features:
  - Smart hover preview positioning to prevent overlap with content
  - Image editing capabilities including rotation, brightness, and contrast
  - Multiple image filters (grayscale, sepia, invert, blur, sharpen)
  - OCR (Optical Character Recognition) to extract text from images
  - Enhanced metadata display including file size information
  - Multiple export format options (PNG, JPEG, TIFF, BMP)
  - Persistent image adjustments across application sessions

### Technical Improvements

- Integration with Vision framework for OCR capabilities
- Integration with Core Image for image adjustments and filtering
- Improved image preview UI with tabs for different functionality
- Memory optimizations for image processing
- Enhanced image export functionality

## Version 0.2.6

### New Features

- Added persistence for clipboard history across app restarts
- Clipboard items (up to 50) are now saved when app quits
- Added automatic reloading of clipboard history on app startup

### Technical Improvements

- Implemented ClipboardStorageManager service for handling persistence
- Added proper handling of image data in persistence
- Ensured consistent state between app and storage
- Implemented clipboard history change notifications
- Improved logging for clipboard storage operations

## Version 0.2.5

### Fixes

- Fixed memory management issue with About window that caused crashes
- Improved window delegation and resource cleanup
- Added proper memory deallocation for modal windows
- Fixed "View Logs" menu item to correctly navigate to the Logs tab
- Added notification system for cross-view communication

## Version 0.2.4

### Changes

- Moved About dialog to a standalone window similar to standard macOS apps
- Removed About tab from settings tabs for cleaner interface
- Enhanced standalone About window with app icon and streamlined layout

## Version 0.2.3

### Changes

- Removed "Launch at Login" functionality due to persistent permission issues
- Simplified application startup
- Improved Rules UI with larger display area and better pattern visibility
- Increased popover size for better usability
- Fixed Logs View UI layout issues and improved readability
- Enhanced log content display with text selection support
- Added functional log level filtering in Logs View
- Fixed About dialog to properly display in the app UI
- Enhanced About view with features list and version information
- Fixed status bar icon click functionality
- Added comprehensive error handling and logging for better diagnostics
- Improved application initialization and window positioning

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
