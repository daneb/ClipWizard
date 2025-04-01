# ClipWizard

ClipWizard is a powerful clipboard manager for macOS that provides automatic clipboard monitoring, sanitization of sensitive information, and efficient access to your clipboard history.

## Current Status

ClipWizard is currently in beta. All core functionality is working, and we're focusing on implementing the remaining features and polishing the UI.

## Features

### Core Functionality
- **Automatic Clipboard Monitoring**: Continuously monitors clipboard activity
- **Clipboard History**: Maintains a searchable history of clipboard items
- **Text and Image Support**: Handles both text and image content
- **Sanitization Engine**: Automatically detects and sanitizes sensitive information
- **Menu Bar Integration**: Quick access through the macOS menu bar

### Sanitization Capabilities
- **Pattern Matching**: Uses regular expressions to identify sensitive content
- **Multiple Sanitization Methods**:
  - **Mask**: Replace content with asterisks (e.g., *******)
  - **Rename**: Replace with alternative values
  - **Obfuscate**: Scramble or hash sensitive data
  - **Remove**: Completely eliminate sensitive information
- **Rule Management**: Create, edit, and manage sanitization rules
- **Rule Testing**: Test your patterns before applying them

### User Experience
- **Quick Access**: Rapidly access clipboard history from the menu bar
- **Search**: Find specific items in your clipboard history
- **Copy on Click**: One-click copying of history items
- **Customizable**: Configure history size, monitoring settings, and more

## Development Plan

### Phase 1: Core Implementation ✅
- [x] Basic app structure and menu bar integration
- [x] Data models for clipboard items and sanitization rules
- [x] Clipboard monitoring service
- [x] Sanitization logic with regex pattern matching

### Phase 2: UI Development ✅
- [x] Clipboard history viewer
- [x] Settings panel
- [x] Rule management interface
- [x] Pattern testing functionality

### Phase 3: Advanced Features 🔄
- [x] Keyboard shortcut support
- [x] Launch-at-login functionality
- [x] Export/import of rules
- [ ] Clipboard synchronization across devices
- [ ] Advanced image handling

### Phase 4: Polish and Optimization ⏳
- [ ] Performance optimizations for large clipboard histories
- [ ] Enhanced security features
- [ ] Accessibility improvements
- [ ] Additional themes and customization options

## Technical Stack

- **Language**: Swift
- **UI Framework**: SwiftUI
- **Target Platform**: macOS Ventura and later

## Getting Started

### Requirements
- macOS Ventura (13.0) or later
- Xcode 15.0 or later for development

### Installation
1. Clone the repository
2. Open the project in Xcode
3. Build and run the application

### Usage
- Access ClipWizard from the menu bar
- Configure sanitization rules in the Settings tab
- View and search clipboard history in the History tab

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
