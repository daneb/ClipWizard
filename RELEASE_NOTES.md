# ClipWizard Release Notes

# ClipWizard 0.7.1

### Summary

😎 Removed annoying initial empty window on app launch.
---

## Version 0.7.0 (Upcoming)

### Summary

This release significantly improves memory management throughout the application to ensure ClipWizard runs efficiently even with large clipboard histories or resource-intensive content.

### Improvements

#### Memory Management

- Implemented comprehensive memory pressure handling system
- Added memory warning detection and automatic cleanup
- Fixed notification observation memory leaks
- Implemented lazy loading for clipboard images
- Added text compression for large clipboard items
- Optimized image processing with autoreleasepools
- Added tiered memory cleanup based on pressure severity

#### Performance

- Reduced memory usage for large clipboard histories
- Improved response time when under memory pressure
- Enhanced background processing of clipboard content
- Optimized image handling for better resource utilization

#### UI Enhancements

- Added loading state indicators for lazy-loaded content
- Improved UI responsiveness during memory-intensive operations

### Installation

Download the latest version from the Releases page and follow the standard installation procedure.

### Upgrade Notes

This version includes significant memory management improvements. It's a recommended update for all users, especially those who frequently copy large text blocks or images.

## Version 0.6.0

### Summary

This release resolves critical database issues, improves thread safety, and enhances the user interface consistency.

### Improvements

#### Database and Thread Safety

- Fixed SQLite multi-threaded access issues that caused crashes
- Implemented improved thread safety for database operations
- Added robust queue detection to prevent recursive deadlocks
- Replaced unavailable SQLite configuration with compatible thread-safety options
- Added WAL (Write-Ahead Logging) mode for improved database stability

#### Memory Management

- Fixed memory management issues with notification observers
- Enhanced bridge pattern implementation to prevent retain cycles
- Improved resource cleanup and lifecycle management
- Added proper self references in closures to address compiler warnings

#### User Interface

- Improved StorageSettingsView layout and consistency with other settings tabs
- Enhanced visual organization of storage statistics
- Added proper padding throughout UI for better visual appearance
- Standardized spacing and layout elements across settings views

### Installation

Download the latest version from the Releases page and follow the standard installation procedure.

### Upgrade Notes

This version includes significant stability improvements for users who experienced crashes. It's a recommended update for all users.

---

## Version 0.5.0 (Apr 2025)

### Summary

This release focuses on simplifying the storage system, fixing critical bugs, and enhancing the overall user interface consistency.

### Improvements

#### Storage System Simplification

- Removed JSON to SQLite migration path
- Made SQLite the exclusive storage backend for all users
- Fixed various storage-related bugs and crashes
- Improved database access to prevent deadlocks

#### UI Refinements

- Enhanced Storage settings layout to match other settings tabs
- Improved spacing and padding consistency across the interface
- Better visual organization of storage statistics
- Added welcome information for new users

### Technical Improvements

- Fixed critical database operations deadlock that caused crashes
- Corrected memory management issues related to notification handling
- Enhanced clipboard monitor implementation with more robust memory handling
- Improved thread safety for database operations
- Implemented queue detection to prevent recursive deadlocks

### Installation

Download the latest version from the Releases page and follow the standard installation procedure.

### Upgrade Notes

This version simplifies the storage system by using SQLite exclusively. Any users still on JSON storage will be automatically migrated.
