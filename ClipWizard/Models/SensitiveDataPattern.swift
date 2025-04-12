import Foundation

/// Defines a sensitive data pattern for automatic detection
struct SensitiveDataPattern: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var pattern: String
    var description: String
    var category: String
    var created: Date
    
    init(id: UUID = UUID(), 
         name: String, 
         pattern: String, 
         description: String = "", 
         category: String,
         created: Date = Date()) {
        self.id = id
        self.name = name
        self.pattern = pattern
        self.description = description
        self.category = category
        self.created = created
    }
    
    /// Returns a valid regular expression from the pattern if possible
    func getRegex() -> NSRegularExpression? {
        do {
            return try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            print("Invalid regex pattern: \(error.localizedDescription)")
            return nil
        }
    }
}

/// Factory for creating default sensitive data patterns
struct SensitiveDataPatternFactory {
    static func createDefaultPatterns() -> [SensitiveDataPattern] {
        return [
            // Credit Card Numbers
            SensitiveDataPattern(
                name: "Credit Card - VISA",
                pattern: "\\b4[0-9]{12}(?:[0-9]{3})?\\b",
                description: "VISA credit card numbers (13-16 digits starting with 4)",
                category: "Payment Information"
            ),
            
            SensitiveDataPattern(
                name: "Credit Card - MasterCard",
                pattern: "\\b(?:5[1-5][0-9]{2}|222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|2720)[0-9]{12}\\b",
                description: "MasterCard credit card numbers (16 digits, starting with 51-55, 2221-2720)",
                category: "Payment Information"
            ),
            
            SensitiveDataPattern(
                name: "Credit Card - AMEX",
                pattern: "\\b3[47][0-9]{13}\\b",
                description: "American Express credit card numbers (15 digits, starting with 34 or 37)",
                category: "Payment Information"
            ),
            
            SensitiveDataPattern(
                name: "Credit Card - Discover",
                pattern: "\\b6(?:011|5[0-9]{2})[0-9]{12}\\b",
                description: "Discover credit card numbers (16 digits, starting with 6011 or 65)",
                category: "Payment Information"
            ),
            
            // Social Security Numbers
            SensitiveDataPattern(
                name: "US Social Security Number",
                pattern: "\\b(?!000|666|9\\d{2})\\d{3}-(?!00)\\d{2}-(?!0000)\\d{4}\\b",
                description: "US Social Security Numbers (format: XXX-XX-XXXX with validation)",
                category: "Government ID"
            ),
            
            // Phone Numbers
            SensitiveDataPattern(
                name: "US Phone Numbers",
                pattern: "\\b(?:\\+?1[-.]?)?\\(?([0-9]{3})\\)?[-.]?([0-9]{3})[-.]?([0-9]{4})\\b",
                description: "US phone numbers in various formats including optional country code",
                category: "Contact Information"
            ),
            
            // Email Addresses
            SensitiveDataPattern(
                name: "Email Addresses",
                pattern: "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b",
                description: "Standard email address format",
                category: "Contact Information"
            ),
            
            // IP Addresses
            SensitiveDataPattern(
                name: "IPv4 Addresses",
                pattern: "\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b",
                description: "IPv4 addresses (format: x.x.x.x)",
                category: "Network Information"
            ),
            
            // API Keys
            SensitiveDataPattern(
                name: "API Keys",
                pattern: "\\b(?:api[-_]?key|auth[-_]?token|secret[-_]?key)\\s*[:=]\\s*['\"]([\\w\\-\\.]{16,64})['\"]",
                description: "Common API key formats with identifiers like 'api_key', 'auth_token', etc.",
                category: "Credentials"
            ),
            
            // Access Tokens
            SensitiveDataPattern(
                name: "OAuth/JWT Tokens",
                pattern: "\\b(?:bearer|access_token|id_token)\\s*[:=]\\s*['\"]([\\w\\-\\.]{24,})['\"]",
                description: "OAuth and JWT tokens often prefixed with 'bearer', 'access_token', etc.",
                category: "Credentials"
            ),
            
            // AWS Keys
            SensitiveDataPattern(
                name: "AWS Access Keys",
                pattern: "\\b(AKIA[0-9A-Z]{16})\\b",
                description: "AWS access key IDs (format: AKIA followed by 16 alphanumeric characters)",
                category: "Credentials"
            ),
            
            SensitiveDataPattern(
                name: "AWS Secret Keys",
                pattern: "\\b[0-9a-zA-Z/+]{40}\\b",
                description: "AWS secret access keys (40 characters)",
                category: "Credentials"
            ),
            
            // Database Connection Strings
            SensitiveDataPattern(
                name: "Database Connection Strings",
                pattern: "\\b(?:mongodb|postgresql|mysql|jdbc)://[^:]+:[^@]+@[^/]+/[^\\s]+",
                description: "Database connection strings with embedded credentials",
                category: "Connection Information"
            ),
            
            // Bitcoin Addresses
            SensitiveDataPattern(
                name: "Bitcoin Addresses",
                pattern: "\\b(bc1|[13])[a-zA-HJ-NP-Z0-9]{25,39}\\b",
                description: "Bitcoin wallet addresses (p2pkh, p2sh, and bech32 formats)",
                category: "Cryptocurrency"
            ),
            
            // Personal Names with Context
            SensitiveDataPattern(
                name: "Personal Names",
                pattern: "\\b(?:name|customer|client|user|patient)\\s*[:=]\\s*['\"]([A-Z][a-z]+(?: [A-Z][a-z]+)+)['\"]",
                description: "Personal names in context (with identifiers like 'name', 'customer', etc.)",
                category: "Personal Information"
            ),
            
            // Password Fields
            SensitiveDataPattern(
                name: "Password Fields",
                pattern: "\\b(?:password|pwd|passcode)\\s*[:=]\\s*['\"]([^'\"]{8,})['\"]",
                description: "Password fields with values of 8 or more characters",
                category: "Credentials"
            ),
            
            // Bank Account Numbers
            SensitiveDataPattern(
                name: "Bank Account Numbers",
                pattern: "\\b(?:account|acct)\\s*#?\\s*[:=]?\\s*['\"]?([0-9]{8,17})['\"]?",
                description: "Bank account numbers (8-17 digits) with context",
                category: "Financial Information"
            )
        ]
    }
}
