import Foundation
import CryptoKit

class SanitizationService: ObservableObject {
    @Published var rules: [SanitizationRule] = []
    
    init(rules: [SanitizationRule]? = nil) {
        self.rules = rules ?? SanitizationRuleFactory.createDefaultRules()
    }
    
    func sanitize(text: String) -> String {
        var result = text
        
        // Sort rules by priority (higher priority processed first)
        let sortedRules = rules.filter({ $0.isEnabled }).sorted(by: { $0.priority > $1.priority })
        
        // Apply each enabled rule
        for rule in sortedRules {
            guard let regex = rule.getRegex() else { continue }
            
            // Find all matches
            let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
            
            // Process matches in reverse order to avoid offset issues when replacing text
            for match in matches.reversed() {
                // Determine the range to sanitize (preferring capture groups if available)
                var rangeToSanitize: Range<String.Index>?
                
                // Look for capture groups, prioritizing them over the full match
                if match.numberOfRanges > 1 {
                    // Try each capture group, taking the first non-empty one
                    for i in 1..<match.numberOfRanges {
                        if let captureRange = Range(match.range(at: i), in: result),
                           !result[captureRange].isEmpty {
                            let capturedText = String(result[captureRange])
                            // Ensure we only sanitize significant content (at least 3 chars)
                            if capturedText.count >= 3 {
                                rangeToSanitize = captureRange
                                break
                            }
                        }
                    }
                }
                
                // If no suitable capture group was found, use the full match
                if rangeToSanitize == nil {
                    rangeToSanitize = Range(match.range, in: result)
                }
                
                // Make sure we have a valid range
                guard let range = rangeToSanitize else { continue }
                let matchedText = String(result[range])
                
                // Skip very short matches to avoid false positives (unless it's a specific format like credit card)
                if matchedText.count < 3 && !rule.name.contains("Credit Card") {
                    continue
                }
                
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
    
    // MARK: - Import and Export Functions
    
    // Export rules to JSON file
    func exportRules(completion: @escaping (Result<URL, Error>) -> Void) {
        RuleImportExportService.shared.exportRules(rules, completion: completion)
    }
    
    // Import rules from JSON file
    func importRules(from url: URL) -> Result<Void, RuleImportError> {
        let result = RuleImportExportService.shared.importRules(from: url)
        
        switch result {
        case .success(let importedRules):
            // Merge with existing rules or replace them
            self.rules = importedRules
            saveRules() // Save to UserDefaults
            return .success(())
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // Show the save panel for exporting rules
    func showExportSavePanel() -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let suggestedFileName = "ClipWizard_Rules_\(dateFormatter.string(from: Date())).json"
        
        return RuleImportExportService.shared.showSavePanel(suggestedFileName: suggestedFileName)
    }
    
    // Show the open panel for importing rules
    func showImportOpenPanel() -> URL? {
        return RuleImportExportService.shared.showOpenPanel()
    }
}
