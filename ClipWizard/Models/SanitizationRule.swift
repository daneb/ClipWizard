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
    
    init(id: UUID = UUID(), name: String, pattern: String, isEnabled: Bool = true, 
         ruleType: SanitizationRuleType = .mask, replacementValue: String? = nil) {
        self.id = id
        self.name = name
        self.pattern = pattern
        self.isEnabled = isEnabled
        self.ruleType = ruleType
        self.replacementValue = replacementValue
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
            // Password patterns
            SanitizationRule(
                name: "Password Fields",
                pattern: "(?i)password\\s*[:=]\\s*['\"]?([^'\"\\s]+)['\"]?",
                ruleType: .mask
            ),
            
            // API Keys
            SanitizationRule(
                name: "API Keys",
                pattern: "(?i)(api[_-]?key|auth[_-]?token)\\s*[:=]\\s*['\"]?([\\w\\-]+)['\"]?",
                ruleType: .mask
            ),
            
            // Connection strings
            SanitizationRule(
                name: "Connection Strings",
                pattern: "(?i)(jdbc|mongodb|mysql|postgresql|connection)[:\"].*?((?:password|pwd)\\s*=\\s*[^;\\s\"]+)",
                ruleType: .mask
            ),
            
            // Credit Card Numbers
            SanitizationRule(
                name: "Credit Card Numbers",
                pattern: "\\b(?:\\d[ -]*?){13,16}\\b",
                ruleType: .mask
            ),
            
            // Email addresses
            SanitizationRule(
                name: "Email Addresses",
                pattern: "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b",
                ruleType: .obfuscate
            )
        ]
    }
}
