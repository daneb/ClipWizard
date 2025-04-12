# ClipWizard 1.0.0 (April 2025 Update)

We're excited to announce ClipWizard 1.0.0, featuring major improvements to our data sanitization system to better protect your sensitive information.

## Enhanced Privacy Protection

The clipboard is often a temporary home for your most sensitive data - passwords, API keys, connection strings, and more. With this update, ClipWizard is now significantly better at identifying and protecting this information:

- **More Comprehensive Detection**: Our enhanced sanitization engine now recognizes many more patterns and variations of sensitive data.

- **Contextual Understanding**: ClipWizard now understands natural language references to sensitive data, such as "My password is..." or "Use this API key:".

- **Improved Database Credential Protection**: Connection strings for MongoDB, PostgreSQL, MySQL and other database types are now properly sanitized in all common formats.

- **New Token Types**: We've added support for detecting modern authentication tokens like JWTs, GitHub tokens, and AWS-style keys.

## Privacy-First Approach

ClipWizard continues to prioritize your privacy with our improved sanitization system:

- **Local Processing**: All sanitization happens locally on your device - your data never leaves your Mac.
  
- **Intelligent Masking**: Only the sensitive portions of your clipboard content are masked, preserving the context around them.

- **False Positive Prevention**: We've implemented smarter algorithms to prevent over-sanitization of non-sensitive data.

## How to Use

Simply copy any text containing sensitive data, and ClipWizard will automatically detect and sanitize it according to your rules. For example:

- "My database password: SecretDbPass123" becomes "My database password: ****************"
- "API key = a1b2c3d4e5f6g7h8" becomes "API key = ****************"
- "mongodb://user:password123@localhost" becomes "mongodb://user:************@localhost"

## Customization

You can customize the sanitization rules in Preferences, including:

- Enabling/disabling specific rule types
- Adjusting the sensitivity of detection
- Creating your own custom patterns
- Prioritizing which rules are applied first

## Other Features

- Automatic clipboard monitoring
- Advanced image handling with OCR and editing
- Keyboard shortcuts for quick access
- Search through clipboard history
- Persistent clipboard history across app restarts

## Installation

- Download the DMG file
- Drag ClipWizard to your Applications folder
- Launch ClipWizard from your Applications folder

## Known Issues

- Permissions needed for accessibility features

## Future Plans

- Performance optimizations
- Enhanced UI polish
- Additional customization options for sanitization rules
