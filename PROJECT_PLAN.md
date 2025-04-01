# ClipWizard Project Plan

This document outlines the development roadmap, architecture, and implementation details for ClipWizard, a macOS clipboard manager with advanced sanitization capabilities.

## Current Status

Currently, the project has completed Phases 1 and 2, and has made significant progress on Phase 3 features:

- ✅ Core clipboard monitoring functionality
- ✅ Menu bar integration and UI
- ✅ Sanitization rules engine
- ✅ Keyboard shortcut support
- ✅ Launch-at-login functionality
- ✅ UI improvements for layout and usability

The app is functional and can be used for its primary purposes of clipboard monitoring and sanitization.

## Project Overview

ClipWizard is designed to serve as a powerful clipboard management tool for macOS users, particularly engineers and developers who frequently work with sensitive information. The app monitors clipboard activity, maintains a history of copied items, and provides tools to automatically sanitize sensitive data.

## Core Requirements

- [x] **Clipboard Monitoring**: Automatically track all clipboard activity
- [x] **Sanitization**: Detect and sanitize sensitive information like passwords, API keys, etc.
- [x] **User Interface**: Provide an intuitive interface for accessing clipboard history and managing settings
- [x] **Extensibility**: Allow users to create and manage their own sanitization rules
- [ ] **Performance**: Ensure minimal system impact while running in the background

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

### Phase 3: Features Enhancement 🔄
- [x] Complete keyboard shortcut support
  - [x] Core HotkeyManager implementation
  - [x] Connect hotkeys to app functions
  - [x] Implement hotkey customization UI
- [x] Launch-at-login functionality
  - [x] Implement service registration with macOS
  - [x] Add toggle in settings
- [ ] Import/export functionality for rules
  - [ ] Add export to JSON/plist
  - [ ] Add import from file
- [ ] Advanced image handling
  - [x] Basic image display in history
  - [ ] Image preview enhancements
  - [ ] Potential OCR integration (future)

### Phase 4: Testing & Optimization ⏳
- [ ] Performance testing with large clipboard histories
- [ ] Memory usage optimization
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
- [ ] Potential automatic clearing of sensitive data after time period

### Performance
- [x] Optimized clipboard monitoring
- [x] Efficient regex matching implementation
- [ ] Performance testing with large histories
- [ ] Memory usage optimization

### Compatibility
- [x] Target macOS Ventura (13.0) and later
- [ ] Verify compatibility with Apple Silicon and Intel Macs

## Next Steps

1. **Implement Rule Import/Export**
   - [ ] Create JSON format for rule export
   - [ ] Add import functionality with validation
   - [ ] Allow sharing of rule collections
   - [ ] Implement file picking and saving interfaces

2. **UI Polish and Refinement**
   - [x] Fix popover positioning issues
   - [x] Improve settings layout for better usability
   - [x] Enhance hotkeys UI for better layout and readability
   - [ ] Add proper app icon
   - [ ] Add visual polish and animations
   - [ ] Improve dark mode support and consistency

3. **Testing & Optimization**
   - [ ] Performance testing with large clipboard histories
   - [ ] Memory usage optimization
   - [ ] Test on different macOS versions (Ventura and Sonoma)
   - [ ] Test with different screen sizes and resolutions

## Milestones

1. **Alpha Release** ✅
   - [x] Core functionality working
   - [x] Basic UI implemented
   - [x] Initial rule set defined

2. **Beta Release** (Current Stage) 🔄
   - [x] Keyboard shortcuts implemented
   - [x] Launch-at-login functionality working
   - [ ] All remaining major features implemented
   - [ ] UI fully polished
   - [ ] Initial user testing completed

3. **1.0 Release** ⏳
   - [ ] Bug fixes from beta testing
   - [ ] Documentation complete
   - [ ] Distribution ready (code signing and notarization)
   - [ ] Marketing materials prepared
