# ClipWizard Release Notes

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
