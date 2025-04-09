# ClipWizard Release Guide

This document outlines the process for building and releasing a new version of ClipWizard on GitHub.

## Prerequisites

- Xcode 15.0 or later
- [create-dmg](https://github.com/create-dmg/create-dmg) utility (can be installed with `brew install create-dmg`)
- Git configured with access to the repository

## Release Process

### 1. Prepare the Release

1. **Update Version Numbers**
   - Open the project in Xcode
   - Select the ClipWizard target
   - Navigate to the "General" tab
   - Update the "Version" field to match your new version (e.g., 0.3.0)
   - Update the "Build" field if necessary

2. **Update CHANGELOG.md**
   - Add a new section for the release
   - List all new features, improvements, and bug fixes
   - Ensure the version number matches the one you set in Xcode

3. **Test the Application**
   - Run all unit tests (`⌘+U` in Xcode)
   - Run UI tests (`⌘+U` in the UI test target)
   - Manually test all core functionality

### 2. Build the Release

#### Option 1: Manual Build

1. **Build Release Version**
   - In Xcode, select "Product" > "Archive"
   - When the Archive is complete, the Organizer window will open
   - Select your archive and click "Distribute App"
   - Choose "Copy App" to export the app without signing
   - Select a location to save the app

2. **Create DMG with create-dmg**
   - Open Terminal
   - Navigate to your project directory
   - Run the included script:
     ```bash
     chmod +x create_dmg.sh
     ./create_dmg.sh
     ```
   - This will create a DMG file with the correct version number

#### Option 2: Use GitHub Actions (Recommended)

1. **Commit Changes**
   - Commit all your changes to the repository:
     ```bash
     git add .
     git commit -m "Prepare release vX.Y.Z"
     ```

2. **Create a Release Tag**
   - Tag the commit with the version:
     ```bash
     git tag vX.Y.Z
     git push origin vX.Y.Z
     ```
   - This will automatically trigger the GitHub Actions workflow

3. **Monitor the Build Process**
   - Go to the "Actions" tab on your GitHub repository
   - Watch the build process for any errors

### 3. Publish the Release

1. **On GitHub**
   - Navigate to the "Releases" section on your GitHub repository
   - If using GitHub Actions, a draft release will be created automatically
   - Edit the release description to add any additional notes
   - Make sure the DMG and ZIP files are attached
   - Click "Publish release" when ready

2. **Update Documentation**
   - If needed, update the README and other documentation to reflect the new version
   - Consider updating screenshots if the UI has changed significantly

### 4. Announce the Release

- Post about the release on relevant platforms
- Update the project website if applicable
- Gather feedback from users for future improvements

## Creating Release Notes

Good release notes should include:

1. **Version Number and Release Date**
2. **New Features**: Describe what's new in user-friendly language
3. **Improvements**: Highlight enhancements to existing features
4. **Bug Fixes**: List any issues that were resolved
5. **Known Issues**: Note any known problems that users should be aware of
6. **Installation Instructions**: Brief guidance for new users

Example format:

```markdown
# ClipWizard 0.3.0 (Release Date: 2025-04-15)

## New Features
- Added ability to customize the clipboard history retention period
- New keyboard shortcuts for quick access to image editing

## Improvements
- Enhanced OCR text extraction with better formatting
- Improved performance for large clipboard histories
- Refined UI animations for smoother experience

## Bug Fixes
- Fixed issue with OCR text not being copyable
- Resolved a memory leak in the image preview component
- Fixed dark mode appearance inconsistencies

## Known Issues
- Launch at login functionality has been temporarily removed due to macOS permission issues

## Installation
Download the DMG file, open it, and drag ClipWizard to your Applications folder.
```

## Versioning Guidelines

We follow [Semantic Versioning](https://semver.org/) for ClipWizard:

- **Major version (X.0.0)**: Incompatible API changes or major feature overhauls
- **Minor version (0.X.0)**: New features in a backward-compatible manner
- **Patch version (0.0.X)**: Backward-compatible bug fixes and minor improvements

## Troubleshooting

### Common Issues

1. **DMG Creation Fails**
   - Ensure create-dmg is properly installed
   - Check for any missing assets like background images or icons

2. **GitHub Actions Build Failure**
   - Check the action logs for detailed error messages
   - Ensure your repository has proper permissions set

3. **Release Assets Missing**
   - Make sure the GitHub Actions workflow completed successfully
   - Check that your tag follows the expected format (vX.Y.Z)

For other issues, please refer to the development team.
