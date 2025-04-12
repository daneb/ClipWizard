import Foundation

enum SanitizationRuleType {
    case mask  // Replace with asterisks or other character
    case rename  // Replace with a specified alternative value
    case obfuscate  // Scramble or hash the value
    case remove  // Remove the sensitive data entirely
}

struct SanitizationRule: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var pattern: String
    var isEnabled: Bool
    var ruleType: SanitizationRuleType
    var replacementValue: String?  // Used for rename rule type
    var priority: Int  // Higher priority rules are processed first
    
    init(id: UUID = UUID(), name: String, pattern: String, isEnabled: Bool = true, 
         ruleType: SanitizationRuleType = .mask, replacementValue: String? = nil,
         priority: Int = 0) {
        self.id = id
        self.name = name
        self.pattern = pattern
        self.isEnabled = isEnabled
        self.ruleType = ruleType
        self.replacementValue = replacementValue
        self.priority = priority
    }
    
    // Returns a valid regular expression from the pattern if possible
    func getRegex() -> NSRegularExpression? {
        do {
            return try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            print("Invalid regex pattern: \(error.localizedDescription)")
            return nil
        }
    }
}

// Extend SanitizationRuleType to be Codable
extension SanitizationRuleType: Codable {
    enum CodingKeys: String, CodingKey {
        case rawValue
    }
    
    enum CodingError: Error {
        case unknownValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        
        switch rawValue {
        case 0: self = .mask
        case 1: self = .rename
        case 2: self = .obfuscate
        case 3: self = .remove
        default: throw CodingError.unknownValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .mask: try container.encode(0)
        case .rename: try container.encode(1)
        case .obfuscate: try container.encode(2)
        case .remove: try container.encode(3)
        }
    }
}

// Factory for creating default sanitization rules
struct SanitizationRuleFactory {
    static func createDefaultRules() -> [SanitizationRule] {
        return [
            // Password patterns - standard format with improved capture
            SanitizationRule(
                name: "Password Fields",
                pattern: "(?i)(?:password|pwd|pass)\\s*[:=]\\s*['\"]?([^'\"\\s;]+)['\"]?",
                ruleType: .mask,
                priority: 10
            ),
            
            // Additional password pattern for conversational format
            SanitizationRule(
                name: "Conversational Password Format",
                pattern: "(?i)(?:my|our|the|account)\\s+(?:password|pwd|pass)\\s+(?:is|=|:)\\s*['\"]?([^'\"\\s;]+)['\"]?",
                ruleType: .mask,
                priority: 20
            ),
            
            // API Keys - standard format with improved capture
            SanitizationRule(
                name: "API Keys",
                pattern: "(?i)(api[_-]?key|auth[_-]?token)\\s*[:=]\\s*['\"]?([\\w\\-\\.]+)['\"]?",
                ruleType: .mask,
                priority: 10
            ),
            
            // API Keys - conversational format
            SanitizationRule(
                name: "Conversational API Key Format",
                pattern: "(?i)(?:my|use|the)\\s+(?:api[_-]?key|auth[_-]?token)\\s+(?:is|=|:)\\s*['\"]?([\\w\\-\\.]+)['\"]?",
                ruleType: .mask,
                priority: 20
            ),
            
            // Connection strings - parameter format
            SanitizationRule(
                name: "Connection Strings with Password Parameter",
                pattern: "(?i)(jdbc|mongodb|mysql|postgresql|connection)[:\"].*?((?:password|pwd)\\s*=\\s*[^;\\s\"]+)",
                ruleType: .mask,
                priority: 10
            ),
            
            // Connection strings - URI format with username:password
            SanitizationRule(
                name: "Connection Strings with User:Password Format",
                pattern: "(?i)(mongodb|postgresql|mysql|jdbc)://[^:@]+:([^@]+)@",
                ruleType: .mask,
                priority: 20
            ),
            
            // Generic connection string with credentials
            SanitizationRule(
                name: "Generic Connection Credentials",
                pattern: "(?i)(?:Server|Data Source)=.+?;.*?(?:Password|Pwd)=([^;]+)",
                ruleType: .mask,
                priority: 15
            ),
            
            // Credit Card Numbers
            SanitizationRule(
                name: "Credit Card Numbers",
                pattern: "\\b(?:\\d[ -]*?){13,16}\\b",
                ruleType: .mask,
                priority: 5
            ),
            
            // Email addresses
            SanitizationRule(
                name: "Email Addresses",
                pattern: "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b",
                ruleType: .obfuscate,
                priority: 5
            ),
            
            // JWT Tokens and OAuth tokens
            SanitizationRule(
                name: "JWT and OAuth Tokens",
                pattern: "\\beyJ[A-Za-z0-9-_]+\\.[A-Za-z0-9-_]+\\.[A-Za-z0-9-_]+\\b",
                ruleType: .mask,
                priority: 15
            ),
            
            // GitHub tokens
            SanitizationRule(
                name: "GitHub Tokens",
                pattern: "\\bgh[ps]_[A-Za-z0-9]{36,}\\b",
                ruleType: .mask,
                priority: 15
            ),
            
            // Generic secrets and tokens with common formats
            SanitizationRule(
                name: "Generic Secrets",
                pattern: "(?i)(?:secret|token|key)\\s*[:=]\\s*['\"]?([\\w\\-\\.]{8,})['\"]?",
                ruleType: .mask,
                priority: 10
            ),
            
            // AWS-style keys
            SanitizationRule(
                name: "AWS Style Keys",
                pattern: "\\b[A-Z0-9]{20}\\b",
                ruleType: .mask,
                priority: 5
            )
        ]
    }
}
