# ClipWizard User Guide

This document provides detailed instructions for using ClipWizard, a powerful clipboard manager for macOS with advanced sanitization capabilities.

## Table of Contents

1. [Installation](#installation)
2. [Getting Started](#getting-started)
3. [Using the Clipboard History](#using-the-clipboard-history)
4. [Working with Images](#working-with-images)
5. [Sanitization Rules](#sanitization-rules)
6. [Settings and Customization](#settings-and-customization)
7. [Keyboard Shortcuts](#keyboard-shortcuts)
8. [Troubleshooting](#troubleshooting)

## Installation

### Installing from GitHub Releases

1. Navigate to the [Releases](https://github.com/daneb/ClipWizard/releases) page
2. Download the latest release (ClipWizard.dmg)
3. Open the DMG file
4. Drag ClipWizard to your Applications folder
5. Open ClipWizard from your Applications folder
   - If macOS shows a security warning, right-click (or Control-click) on ClipWizard and select "Open"

### Building from Source

If you prefer to build from source:

1. Clone the repository:
   ```
   git clone https://github.com/daneb/ClipWizard.git
   ```
2. Open the project in Xcode:
   ```
   cd ClipWizard
   open ClipWizard.xcodeproj
   ```
3. Build the project (⌘+B) and run (⌘+R)

## Getting Started

### First Launch

1. When you first launch ClipWizard, it will appear in your menu bar as an icon
2. Click the icon to open the main ClipWizard interface
3. You'll see two main tabs: History and Settings

### Permissions

ClipWizard may request certain permissions to function properly:

1. **Accessibility Permissions**: Required for capturing keyboard shortcuts
   - If prompted, click "Open System Preferences" and add ClipWizard to the allowed applications list

### Menu Bar Access

The ClipWizard menu bar icon provides quick access to:

- Clipboard history
- Settings and preferences
- Quickly copy recent items
- Exit the application

## Using the Clipboard History

### Viewing Your Clipboard History

1. Click the ClipWizard icon in the menu bar
2. The History tab shows your clipboard items in chronological order (newest first)
3. Each item shows:
   - A preview of the content
   - The time it was copied
   - An icon indicating whether it's text or an image

### Searching for Items

1. Type in the search field at the top of the History tab
2. Results will update in real-time as you type
3. Search works for both text content and image OCR text (if extracted)

### Using History Items

- **Copy an item**: Click on any item to copy it back to your clipboard
- **View details**: Click the info (i) button to see full details, including:
  - Original content
  - Sanitized content (if applicable)
  - Timestamp information

### Clearing History

1. Go to the History tab
2. Click the "Clear History" button at the bottom
3. Confirm the action in the dialog

## Working with Images

### Image Preview

1. Hover over an image item in the history to see a preview
2. Click on an image item to open the detailed view

### Image Details View

The image details view has two tabs:

#### Preview Tab

- Zoom controls to adjust image size
- Pan functionality (click and drag the image)
- Reset button to return to original view
- Metadata display (dimensions, file size)

#### Edit Tab

- **Rotation**: Rotate the image with slider or buttons
- **Adjustments**: Modify brightness and contrast
- **Filters**: Apply various filters (Grayscale, Sepia, Invert, Blur, Sharpen)
- **Export Format**: Select the format for saving (PNG, JPEG, TIFF, BMP)

### Using OCR (Optical Character Recognition)

1. In the image detail view, click the "Extract Text (OCR)" button
2. ClipWizard will process the image and display any recognized text
3. The extracted text can be:
   - Selected and copied manually
   - Copied in full using the "Copy OCR Text" button

### Saving Images

1. In the image detail view, click the "Save Image" button
2. Choose a location and filename
3. The image will be saved in your selected export format

## Sanitization Rules

Sanitization rules allow ClipWizard to automatically detect and modify sensitive information in your clipboard.

### Creating a New Rule

1. Go to the Settings tab
2. Select the Rules sub-tab
3. Click "Add Rule"
4. Fill in the rule details:
   - **Name**: A descriptive name for the rule
   - **Pattern**: A regular expression to match sensitive content
   - **Sanitization Method**:
     - **Mask**: Replace with asterisks or other mask characters
     - **Rename**: Replace with a different value
     - **Obfuscate**: Scramble the content
     - **Remove**: Delete the content entirely
   - **Replacement Value**: For the "Rename" method, specify the replacement text
   - **Enabled**: Toggle to enable/disable the rule

### Testing Rules

1. In the rule edit view, enter test text in the "Test Text" field
2. Click "Test" to see how your rule would affect the text
3. Adjust the pattern or sanitization method as needed

### Managing Rules

- **Edit a rule**: Click the edit button next to any rule
- **Delete a rule**: Click the delete button next to any rule
- **Enable/Disable**: Toggle the checkbox next to any rule

### Importing and Exporting Rules

1. **Export Rules**:

   - In the Rules tab, click "Export Rules"
   - Choose a location to save the rules file
   - Rules are saved in JSON format

2. **Import Rules**:
   - In the Rules tab, click "Import Rules"
   - Select a previously exported rules file
   - Review the imported rules and adjust as needed

## Settings and Customization

### General Settings

1. Go to the Settings tab
2. Adjust the following options:
   - **History Size**: Maximum number of items to keep in history
   - **Startup**: Launch ClipWizard when your computer starts
   - **Default View**: Choose which tab to show first when opening ClipWizard

### Hotkeys Settings

1. Go to the Settings tab and select the Hotkeys sub-tab
2. Configure keyboard shortcuts for:
   - **Show/Hide ClipWizard**: Toggle the main interface
   - **Quick Paste**: Access clipboard history directly
   - **Clear History**: Quickly clear the clipboard history

To set a hotkey:

1. Click in the hotkey field
2. Press the desired key combination
3. The hotkey will be recorded and activated

### Logs

The Logs view helps troubleshoot issues:

1. Go to the Settings tab and select the Logs sub-tab
2. View application logs with timestamps
3. Filter logs by severity (Info, Warning, Error)
4. Use the "Copy Logs" button to copy logs for support

## Keyboard Shortcuts

ClipWizard supports the following default keyboard shortcuts:

- **⌘+⇧+V**: Open ClipWizard clipboard history
- **⌘+⇧+X**: Show settings
- **Escape**: Close the current view
- **⌘+F**: Focus on search field (in History view)
- **⌘+,**: Open settings

These shortcuts can be customized in the Hotkeys settings tab.

## Troubleshooting

### Common Issues

#### ClipWizard Not Appearing in Menu Bar

1. Check if ClipWizard is running in Activity Monitor
2. If running but not visible, quit and restart the application
3. Ensure you have sufficient space in your menu bar

#### Clipboard Monitoring Issues

1. Make sure you've granted necessary permissions
2. Restart ClipWizard
3. If problems persist, check the Logs tab for error messages

#### OCR Not Working or Inaccurate

1. OCR works best with clear, high-contrast images
2. Some fonts or handwriting may not be recognized correctly
3. Try adjusting the image (increase contrast, apply sharpening) before OCR

#### Performance Issues

1. If ClipWizard is running slowly, try:
   - Reducing your clipboard history size
   - Clearing old history items
   - Restarting the application

### Using Logs for Troubleshooting

1. Go to Settings → Logs
2. Look for errors related to your issue
3. When contacting support, include relevant log entries

### Reporting Bugs

If you encounter a bug:

1. Check the Logs tab for error messages
2. Take screenshots of the issue if possible
3. Report the bug on the [GitHub Issues page](https://github.com/daneb/ClipWizard/issues) with detailed information

---

If you need further assistance, please create an issue on the ClipWizard GitHub repository.
