# ClipWizard Project Plan

This document outlines the development roadmap, architecture, and implementation details for ClipWizard, a macOS clipboard manager with advanced sanitization capabilities.

## Current Status

Currently, the project has completed Phases 1 and 2, and has made significant progress on Phase 3 features:

- ✅ Core clipboard monitoring functionality
- ✅ Menu bar integration and UI
- ✅ Sanitization rules engine
- ✅ Keyboard shortcut support
- ❌ Launch-at-login functionality (removed due to permission issues)
- ✅ UI improvements for layout and usability
- ✅ Fixed AppleScript permission issues
- ✅ Enhanced error handling for system integrations
- ✅ Fixed Settings tab navigation issues
- ✅ Added comprehensive logging system for diagnostics and troubleshooting
- ✅ Code refactoring for improved maintainability

The app is functional and can be used for its primary purposes of clipboard monitoring and sanitization.

## Project Overview

ClipWizard is designed to serve as a powerful clipboard management tool for macOS users, particularly engineers and developers who frequently work with sensitive information. The app monitors clipboard activity, maintains a history of copied items, and provides tools to automatically sanitize sensitive data.

## Core Requirements

- [x] **Clipboard Monitoring**: Automatically track all clipboard activity
- [x] **Sanitization**: Detect and sanitize sensitive information like passwords, API keys, etc.
- [x] **User Interface**: Provide an intuitive interface for accessing clipboard history and managing settings
- [x] **Extensibility**: Allow users to create and manage their own sanitization rules
- [x] **Performance**: Ensure minimal system impact while running in the background
- [x] **Persistence**: Maintain clipboard history across app restarts

## Architecture

### 1. Data Models

#### ClipboardItem

- [x] Properties: ID, timestamp, content type (text/image), original content, sanitized content
- [x] Responsible for representing individual clipboard entries

#### SanitizationRule

- [x] Properties: ID, name, pattern (regex), rule type, replacement value, enabled status
- [x] Responsible for defining how specific types of sensitive data should be handled

### 2. Services

#### ClipboardMonitor

- [x] Monitor clipboard changes and detect content type
- [x] Add items to history with proper metadata
- [x] Manage history size according to user preferences
- [x] Provide methods to clear history and copy items back to clipboard

#### SanitizationService

- [x] Apply sanitization rules using regex patterns
- [x] Manage different sanitization types (mask, rename, obfuscate, remove)
- [x] Provide CRUD operations for rules
- [x] Save/load rules from UserDefaults

#### HotkeyManager

- [x] Base implementation for registering system-wide keyboard shortcuts
- [x] Connect hotkeys to app functionality
- [x] Provide user interface for customizing shortcuts

### 3. User Interface

#### Main Views

- [x] ClipboardHistoryView: Display and search clipboard history
- [x] SettingsView: Configure app behavior and manage sanitization rules
- [x] RuleEditView: Create and edit sanitization rules

#### Components

- [x] ClipboardItemRow: Display individual clipboard items in the history list
- [x] ClipboardItemDetailView: Show detailed view of clipboard items
- [x] ImagePreviewOverlay: Show image previews on hover
- [x] Tab-based navigation for settings
- [x] Menu bar integration with dropdown menu

## Implementation Progress

### Phase 1: Foundation ✅

- [x] Set up project structure and basic macOS app
- [x] Implement core data models (ClipboardItem, SanitizationRule)
- [x] Create menu bar integration with status item
- [x] Implement clipboard monitoring service
- [x] Develop sanitization logic with regex pattern matching

### Phase 2: User Interface ✅

- [x] Design and implement clipboard history view with search
- [x] Create settings panel with tab navigation
- [x] Build rule management interface
- [x] Implement sanitization rule editing
- [x] Add UI for configuring app preferences
- [x] Fix UI layout and positioning for popovers

### Phase 3: Features Enhancement ✅

- [x] Complete keyboard shortcut support
  - [x] Core HotkeyManager implementation
  - [x] Connect hotkeys to app functions
  - [x] Implement hotkey customization UI
- [x] Launch-at-login functionality (Removed in v0.2.3)
  - [x] ~~Implement service registration with macOS~~
  - [x] ~~Add toggle in settings~~
  - [x] ~~Fix AppleScript permission issues~~
  - [x] ~~Add user-friendly permission request dialogs~~
  - [x] Functionality removed due to persistent permission issues on macOS
- [x] Import/export functionality for rules
  - [x] Add export to JSON format
  - [x] Add import from file
  - [x] Add sharing UI
- [x] Advanced image handling
  - [x] Basic image display in history
  - [x] Image preview enhancements
  - [x] OCR integration for text extraction
  - [x] Image editing capabilities
  - [x] Multiple export formats
- [x] Code Quality Improvements
  - [x] Refactor large files into smaller, focused components
  - [x] Extract reusable utilities
  - [x] Improve component organization
  - [x] Enhance code readability and maintainability

### Phase 4: Testing & Optimization 🔄

- [x] Performance testing with large clipboard histories
- [x] Memory usage optimization
- [x] Clipboard history persistence
- [ ] Add automated tests
  - [ ] Unit tests for services
  - [ ] UI tests for main interactions
- [ ] User testing and feedback collection

### Phase 5: Release Preparation ⏳

- [ ] App distribution preparation
  - [ ] Code signing
  - [ ] Notarization
- [ ] App icon and branding design
- [ ] Complete documentation
  - [x] README
  - [x] Project plan
  - [ ] User guide

## Technical Considerations

### Privacy & Security

- [x] No network access for clipboard data
- [x] Local-only processing
- [x] Secure storage of clipboard history
- [x] Comprehensive logging system for diagnostics (no sensitive data logged)
- [ ] Potential automatic clearing of sensitive data after time period

### Performance

- [x] Optimized clipboard monitoring
- [x] Efficient regex matching implementation
- [x] Performance testing with large histories
- [x] Memory usage optimization
- [x] Improved code structure for better maintainability

### Compatibility

- [x] Target macOS Ventura (13.0) and later
- [ ] Verify compatibility with Apple Silicon and Intel Macs

## Next Steps

1. **UI Polish and Refinement**

   - [x] Fix popover positioning issues
   - [x] Improve settings layout for better usability
   - [x] Enhance hotkeys UI for better layout and readability
   - [x] Add proper error handling and user feedback
   - [x] Fixed tab navigation issues between History and Settings views
   - [x] Improved code structure with component-based architecture
   - [x] Add proper app icon
   - [ ] Add visual polish and animations
   - [ ] Improve dark mode support and consistency
   - [ ] Clipboard window renders too far below its menu bar icon

2. **Testing & Optimization**

   - [x] Refactor code for better maintainability
   - [ ] Complete performance testing with large clipboard histories
   - [ ] Optimize memory usage further
   - [ ] Test on different macOS versions (Ventura and Sonoma)
   - [ ] Test with different screen sizes and resolutions
   - [ ] Test to ensure default sanitization rules works effectively or intuitively

3. **Automated Testing**
   - [x] Implement unit tests for core services
   - [x] Add UI tests for critical user flows
   - [x] Create test utilities and mocks

## Milestones

1. **Alpha Release** ✅

   - [x] Core functionality working
   - [x] Basic UI implemented
   - [x] Initial rule set defined

2. **Beta Release** (Current Stage) 🔄

   - [x] Keyboard shortcuts implemented
   - [x] Rule import/export functionality implemented
   - [x] Advanced image handling features implemented
   - [x] Improved code structure with better component organization
   - [ ] UI fully polished
   - [ ] Initial user testing completed

3. **1.0 Release** ⏳
   - [ ] Bug fixes from beta testing
   - [ ] Documentation complete
   - [ ] Distribution ready (code signing and notarization)
   - [ ] Marketing materials prepared
