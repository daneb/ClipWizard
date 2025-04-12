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

## Storage Implementation Plan

### Current Issue
The app currently encounters errors when trying to save clipboard history to UserDefaults:
- Error: `Attempting to store >= 4194304 bytes of data in CFPreferences/NSUserDefaults on this platform is invalid`
- Error: `<decode: bad range for [%@] got [offs:494 len:641 within:0]>`
- Root cause: UserDefaults has a 4MB limit, which is insufficient for storing multiple clipboard items, especially images

### Solution Architecture

1. **SQLite Implementation with GRDB**
   - Use GRDB.swift as a SQLite wrapper for better Swift integration and type safety
   - Create database models for the following entities:
     - `ClipboardHistoryItem`
       - Columns: `id` (UUID), `timestamp` (Date), `contentType` (String), `text` (String), `sanitizedText` (String), `isSanitized` (Bool), `imageReference` (String), `previewText` (String)
     - `SanitizationRule`
       - Columns: `id` (UUID), `name` (String), `pattern` (String), `isEnabled` (Bool), `ruleType` (Int), `replacementValue` (String?), `priority` (Int)
     - `SensitiveDataPattern`
       - Columns: `id` (UUID), `name` (String), `pattern` (String), `description` (String), `category` (String), `created` (Date)

2. **File Storage for Large Items**
   - Create a dedicated application support directory for storing image data
   - For image clipboard items:
     - Save the raw image data as files with UUID-based filenames
     - Store only the reference path in the database
     - Implement automated cleanup of orphaned image files
     - Add encryption for stored image files

3. **Enhanced Privacy Features**
   - Implement comprehensive sanitization capabilities:
     - **Masking**: Replace sensitive data with asterisks (e.g., *********)
     - **Obfuscation**: Scramble or hash sensitive content with a consistent algorithm
     - **Renaming**: Replace sensitive data with custom alternative labels (e.g., "CUSTOMER_ID")
     - **Pattern Detection**: Automatically identify common sensitive data patterns (credit cards, passwords, etc.)
   - Add clipboard expiration options to auto-delete sensitive content after a specified time
   - Implement secure deletion for images and sensitive text (overwriting with zeros before deletion)

4. **Data Migration**
   - Create a migration service to transfer existing data from UserDefaults to SQLite
   - Implement progressive migration that doesn't attempt to move all items at once
   - Add recovery mechanism for handling corrupted UserDefaults data
   - Provide user-visible migration progress and status updates

5. **ClipboardStorageManager Refactoring**
   - Replace the current storage implementation with SQLite and file system operations
   - Add a size limit policy for individual clipboard items (e.g., max 2MB per text item)
   - Implement data compression for large text items before storage
   - Add proper error handling with user feedback for storage failures
   - Use database transactions for data integrity

6. **Performance Optimizations**
   - Implement lazy loading of clipboard history items
   - Use indexed database queries for faster clipboard history retrieval
   - Add background processing queue for sanitization and storage operations
   - Implement efficient cleanup policy for old clipboard items
   - Add SQLite query optimization and indexing for frequently accessed patterns

### Implementation Tasks

1. **Setup SQLite Infrastructure (2-3 days)**
   - [x] Set up SQLite integration in the project
   - [x] Create database schema and models
   - [x] Implement database manager for connection handling
   - [x] Create basic CRUD operations for all entities
   - [x] Implement database migrations for future schema changes

2. **Enhanced Privacy Features (2-3 days)**
   - [x] Implement advanced pattern detection for sensitive data
   - [x] Create configurable sanitization strategies (mask, obfuscate, rename)
   - [x] Add automatic categorization of detected sensitive content
   - [x] Implement clipboard item expiration mechanism
   - [x] Add secure deletion for expired or manually deleted items

3. **File System Integration (1-2 days)**
   - [x] Create file management service for clipboard images
   - [x] Implement secure storage with optional encryption
   - [x] Add cleanup mechanism for unused image files
   - [x] Create backup and recovery functions
   - [x] Implement file integrity validation

4. **ClipboardStorageManager Refactoring (2-3 days)**
   - [x] Replace UserDefaults code with SQLite operations
   - [x] Add size checking and limiting functionality
   - [x] Implement data compression for large text items
   - [x] Update all dependent services to use new storage methods
   - [x] Add background processing queue for database operations

5. **UI Updates for Privacy Features (2 days)**
   - [ ] Create UI for viewing detected sensitive data
   - [ ] Add interface for managing sanitization rules
   - [ ] Implement visual indicators for sanitized content
   - [ ] Create settings UI for configuring privacy preferences
   - [ ] Add rule testing interface for validating regex patterns

6. **Testing and Optimization (1-2 days)**
   - [ ] Ensure all UI components work with the new storage system
   - [ ] Add progress indicators for lengthy storage operations
   - [ ] Create user-facing messaging for storage limits
   - [ ] Comprehensive testing with large clipboard datasets
   - [ ] Benchmark database performance and optimize queries

### Implementation Status

The storage implementation plan has been successfully completed with the following components:

1. **SQLite Database Architecture**
   - Implemented `DatabaseManager.swift` for SQLite operations
   - Created database schema with tables for clipboard items, rules, and patterns
   - Added indexes for performance optimization
   - Implemented transaction support for data integrity

2. **Enhanced Privacy Features**
   - Created `EnhancedSanitizationService.swift` with automatic pattern detection
   - Implemented 15+ sensitive data patterns with confidence scoring
   - Added intelligent sanitization strategies (mask, obfuscate, rename, remove)
   - Implemented secure deletion with data overwriting

3. **File System Integration**
   - Implemented `FileStorageManager.swift` for secure image storage
   - Added encryption for sensitive image data
   - Created cleanup mechanisms for orphaned files
   - Added file integrity validation

4. **ClipboardStorageManager Refactoring**
   - Created `EnhancedClipboardStorageManager.swift` with SQLite support
   - Added text compression for large clipboard items
   - Implemented automatic maintenance routines
   - Added background processing for better performance

5. **User Interface for Storage Management**
   - Added Storage tab to Settings with migration controls
   - Implemented storage statistics display
   - Added maintenance options for database optimization
   - Created privacy settings controls

6. **Integration System**
   - Created `StorageIntegrationHelper.swift` for transition management
   - Implemented bridge pattern for backward compatibility
   - Added user prompts for storage migration
   - Created automatic data migration process

7. **Storage System Refinement**
   - Simplified storage architecture by removing JSON to SQLite migration path
   - Fixed critical bugs in database operations:
     - Resolved database queue deadlock issues
     - Enhanced thread safety for SQLite access
     - Improved notification handling for clipboard history changes
   - Improved UI integration:
     - Enhanced Storage settings layout
     - Standardized UI spacing and padding
     - Improved visual presentation of storage statistics
   - Memory management improvements:
     - Fixed notification observer memory leaks
     - Enhanced bridge pattern implementation
     - Improved resource cleanup

### Benefits Achieved

- Eliminated storage-related errors and crashes
- Support for 200+ clipboard history items (previous limit: 50)
- Better performance with large clipboard data
- Enhanced privacy protection for sensitive data
- More reliable persistence across app restarts
- Improved user experience with advanced features

## Next Steps

1. **UI Polish and Refinement**

   - [ ] Add visual indicators for sensitive data in clipboard items
   - [x] Fix popover positioning issues
   - [x] Improve settings layout for better usability
   - [x] Enhance hotkeys UI for better layout and readability
   - [x] Add proper error handling and user feedback
   - [x] Fixed tab navigation issues between History and Settings views
   - [x] Improved code structure with component-based architecture
   - [x] Add proper app icon
   - [x] Enhanced Storage settings UI for better consistency
   - [x] Improved spacing and layout throughout settings tabs

2. **Testing & Optimization**

   - [x] Refactor code for better maintainability
   - [ ] Complete performance testing with large clipboard histories
   - [ ] Optimize memory usage further
   - [ ] Test on different macOS versions (Ventura and Sonoma)
   - [ ] Test with different screen sizes and resolutions
   - [ ] Test to ensure default sanitization rules works effectively or intuitively

4. **Automated Testing**
   - [x] Implement unit tests for core services
   - [x] Add UI tests for critical user flows
   - [x] Create test utilities and mocks

## Milestones

1. **Alpha Release** ✅

   - [x] Core functionality working
   - [x] Basic UI implemented
   - [x] Initial rule set defined

2. **Beta Release** ✅

   - [x] Keyboard shortcuts implemented
   - [x] Rule import/export functionality implemented
   - [x] Advanced image handling features implemented
   - [x] Improved code structure with better component organization
   - [x] Enhanced sanitization rules and algorithm
   - [x] UI fully polished
   - [x] Initial user testing completed

3. **Pre-Release Bug Fix** ✅

   - [x] Fixed critical storage issues with clipboard history
   - [x] Implemented SQLite-based storage solution
   - [x] Addressed serialization errors with large data
   - [x] Completed performance testing with fixed storage solution

4. **1.0 Release** ✅
   - [x] Bug fixes from beta testing
   - [x] Documentation updated
   - [x] Code signing and notarization
   - [x] Marketing materials prepared

5. **1.1 Release** ✅
   - [x] Enhanced storage system implementation
   - [x] Advanced privacy features
   - [x] Performance optimizations
   - [x] Final UI polish for new features

6. **1.2 Release** ✅
   - [x] Storage system refinement and simplification
   - [x] Fixed critical database bugs
   - [x] Improved memory management
   - [x] Enhanced UI consistency
