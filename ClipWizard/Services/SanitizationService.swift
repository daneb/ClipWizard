import Foundation
import CryptoKit

class SanitizationService: ObservableObject {
    @Published var rules: [SanitizationRule] = []
    
    init(rules: [SanitizationRule]? = nil) {
        self.rules = rules ?? SanitizationRuleFactory.createDefaultRules()
    }
    
    func sanitize(text: String) -> String {
        var result = text
        
        // Apply each enabled rule
        for rule in rules.filter({ $0.isEnabled }) {
            guard let regex = rule.getRegex() else { continue }
            
            // Find all matches
            let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
            
            // Process matches in reverse order to avoid offset issues when replacing text
            for match in matches.reversed() {
                // Get the matching range and text
                guard let range = Range(match.range, in: result) else { continue }
                let matchedText = String(result[range])
                
                // Apply the rule based on its type
                let replacement: String
                switch rule.ruleType {
                case .mask:
                    replacement = maskText(matchedText)
                case .rename:
                    replacement = rule.replacementValue ?? "[REDACTED]"
                case .obfuscate:
                    replacement = obfuscateText(matchedText)
                case .remove:
                    replacement = ""
                }
                
                // Replace the matched text with the sanitized version
                result.replaceSubrange(range, with: replacement)
            }
        }
        
        return result
    }
    
    private func maskText(_ text: String) -> String {
        // Simple masking with asterisks, preserving length
        return String(repeating: "*", count: text.count)
    }
    
    private func obfuscateText(_ text: String) -> String {
        // Hash the text to create an obfuscated version
        // For display purposes, we'll use the first 8 characters of the hash
        if let data = text.data(using: .utf8) {
            let hashed = SHA256.hash(data: data)
            let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
            return "[OBFUSCATED:" + String(hashString.prefix(8)) + "]"
        }
        return "[OBFUSCATED]"
    }
    
    // Add a new rule
    func addRule(_ rule: SanitizationRule) {
        rules.append(rule)
    }
    
    // Update an existing rule
    func updateRule(_ rule: SanitizationRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
        }
    }
    
    // Delete a rule
    func deleteRule(_ rule: SanitizationRule) {
        rules.removeAll { $0.id == rule.id }
    }
    
    // Enable or disable a rule
    func toggleRule(_ rule: SanitizationRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            var updatedRule = rules[index]
            updatedRule.isEnabled = !updatedRule.isEnabled
            rules[index] = updatedRule
        }
    }
    
    // Reset to default rules
    func resetToDefaultRules() {
        rules = SanitizationRuleFactory.createDefaultRules()
    }
    
    // Save rules to UserDefaults
    func saveRules() {
        if let encoded = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(encoded, forKey: "sanitizationRules")
        }
    }
    
    // Load rules from UserDefaults
    func loadRules() {
        if let savedRules = UserDefaults.standard.data(forKey: "sanitizationRules"),
           let decodedRules = try? JSONDecoder().decode([SanitizationRule].self, from: savedRules) {
            rules = decodedRules
        } else {
            // If no saved rules, use defaults
            rules = SanitizationRuleFactory.createDefaultRules()
        }
    }
}
