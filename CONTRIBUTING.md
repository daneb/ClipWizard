# Contributing to ClipWizard

Thank you for your interest in contributing to ClipWizard! This document provides guidelines and instructions for contributing to this project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for everyone. Please be kind and constructive in your communications.

## How Can I Contribute?

### Reporting Bugs

If you find a bug in ClipWizard, please create an issue on GitHub with the following information:

1. **Title**: A clear, descriptive title for the issue
2. **Description**: Detailed steps to reproduce the bug
3. **Expected Behavior**: What you expected to happen
4. **Actual Behavior**: What actually happened
5. **Screenshots**: If applicable, add screenshots to help explain the problem
6. **Environment**:
   - macOS version
   - ClipWizard version
   - Any relevant system information

### Suggesting Enhancements

If you have ideas for new features or improvements, please create an issue with:

1. **Title**: A clear, descriptive title for your suggestion
2. **Description**: Detailed explanation of the feature or enhancement
3. **Use Case**: Why this would be valuable to ClipWizard users
4. **Additional Context**: Any other relevant information or mockups

### Pull Requests

We welcome pull requests for bug fixes, enhancements, or documentation improvements. Here's how to submit a PR:

1. **Fork the Repository**: Create your own fork of ClipWizard
2. **Create a Branch**: Make your changes in a new branch
   ```
   git checkout -b feature/your-feature-name
   ```
   or
   ```
   git checkout -b fix/your-bug-fix
   ```
3. **Make Changes**: Implement your changes, following our coding style
4. **Test Your Changes**: Make sure your changes don't break existing functionality
5. **Commit Changes**: Write clear, concise commit messages
   ```
   git commit -m "Brief description of your changes"
   ```
6. **Push to Your Fork**: Upload your changes to your fork
   ```
   git push origin feature/your-feature-name
   ```
7. **Create a Pull Request**: Submit a PR against the main branch of the ClipWizard repository
8. **Code Review**: Wait for code review and address any requested changes

## Development Setup

### Prerequisites

- macOS Ventura (13.0) or later
- Xcode 15.0 or later
- Git

### Getting Started

1. Clone the repository:
   ```
   git clone https://github.com/daneb/ClipWizard.git
   ```
2. Open the project in Xcode:
   ```
   open ClipWizard.xcodeproj
   ```
3. Build and run the application (⌘+R)

### Project Structure

- **ClipWizard/**: Main app source code
  - **Models/**: Data models
  - **Views/**: UI components
  - **Services/**: Core functionality services
  - **Utils/**: Helper methods and extensions
- **ClipWizardTests/**: Unit tests
- **ClipWizardUITests/**: UI tests

## Coding Guidelines

### Swift Style Guide

- Follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use descriptive variable and function names
- Add documentation comments for public methods and types
- Keep functions small and focused on a single task
- Use Swift's strong typing to prevent errors

### SwiftUI Best Practices

- Separate view logic from business logic
- Create reusable view components
- Use appropriate property wrappers (@State, @Binding, @ObservedObject, etc.)
- Follow Apple's Human Interface Guidelines for macOS

### Git Workflow

- Keep commits small and focused on a single change
- Write clear commit messages:
  - Start with a verb in present tense (e.g., "Add", "Fix", "Update")
  - First line should be a summary under 72 characters
  - Optionally followed by a blank line and a more detailed explanation
- Rebase your branch if needed before submitting a PR

## Testing

- Write unit tests for new functionality
- Ensure existing tests pass with your changes
- Test your changes on multiple macOS versions if possible

## Documentation

When adding new features or making significant changes, please update the relevant documentation:

- Update README.md if applicable
- Add or update code documentation comments
- Consider updating the user guide if needed

## License

By contributing to ClipWizard, you agree that your contributions will be licensed under the same [MIT License](LICENSE) that covers the project.

## Questions?

If you have any questions about contributing, please open an issue for discussion.

Thank you for helping improve ClipWizard!
