import Foundation
import CryptoKit
import AppKit

/// Service responsible for sanitizing sensitive information in clipboard content
class EnhancedSanitizationService: ObservableObject {
    // Published properties for UI binding
    @Published var rules: [SanitizationRule] = []
    @Published var sensitivePatterns: [SensitiveDataPattern] = []
    @Published var detectionEnabled: Bool = true
    @Published var sanitizeImagesText: Bool = true
    
    // Database access objects
    private let ruleDAO = SanitizationRuleDAO()
    private let patternDAO = SensitiveDataPatternDAO()
    
    // Detection results for the most recent sanitization
    private(set) var lastDetectionResults: [SensitiveDataDetection] = []
    
    init() {
        // Load rules and patterns from the database
        loadRules()
        loadPatterns()
        
        // Load user preferences
        loadPreferences()
    }
    
    // MARK: - Sanitization Functions
    
    /// Sanitizes text content according to enabled rules
    /// - Parameter text: The text to sanitize
    /// - Returns: The sanitized text
    func sanitize(text: String) -> String {
        var result = text
        lastDetectionResults = []
        
        if text.isEmpty {
            return result
        }
        
        // First, apply automatic pattern detection if enabled
        if detectionEnabled {
            // Keep track of all detected patterns to avoid overlapping replacements
            var detections: [SensitiveDataDetection] = []
            
            // Find matches for each sensitive data pattern
            for pattern in sensitivePatterns {
                guard let regex = pattern.getRegex() else { continue }
                
                let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
                
                for match in matches {
                    // Determine the range to sanitize
                    var rangeToSanitize: Range<String.Index>?
                    
                    // Look for capture groups, prioritizing them over the full match
                    if match.numberOfRanges > 1 {
                        // Try each capture group, taking the first non-empty one
                        for i in 1..<match.numberOfRanges {
                            if let captureRange = Range(match.range(at: i), in: result),
                               !result[captureRange].isEmpty {
                                let capturedText = String(result[captureRange])
                                // Ensure we only sanitize significant content
                                if capturedText.count >= 3 {
                                    rangeToSanitize = captureRange
                                    break
                                }
                            }
                        }
                    }
                    
                    // If no suitable capture group was found, use the full match
                    if rangeToSanitize == nil, let fullRange = Range(match.range, in: result) {
                        rangeToSanitize = fullRange
                    }
                    
                    // Make sure we have a valid range
                    guard let range = rangeToSanitize else { continue }
                    let matchedText = String(result[range])
                    
                    // Skip very short matches to avoid false positives
                    if matchedText.count < 3 {
                        continue
                    }
                    
                    // Record this detection
                    let detection = SensitiveDataDetection(
                        pattern: pattern,
                        matchedText: matchedText,
                        range: range,
                        confidence: calculateConfidence(text: matchedText, pattern: pattern)
                    )
                    
                    // Add to our collection of detections
                    detections.append(detection)
                }
            }
            
            // Sort detections by confidence (highest first)
            detections.sort { $0.confidence > $1.confidence }
            
            // Store detections for reference
            lastDetectionResults = detections
            
            // Apply automatic sanitization for high-confidence detections
            for detection in detections where detection.confidence >= 0.8 {
                // For automatic sanitization, use masking by default
                let replacement = maskText(detection.matchedText)
                result.replaceSubrange(detection.range, with: replacement)
            }
        }
        
        // Next, apply user-defined rules
        // Sort rules by priority (higher priority processed first)
        let sortedRules = rules.filter({ $0.isEnabled }).sorted(by: { $0.priority > $1.priority })
        
        // Process each rule
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
                            // Ensure we only sanitize significant content
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
                
                // Skip very short matches to avoid false positives
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
    
    /// Process an image item for OCR and sanitize any text found in the image
    /// - Parameter item: The clipboard item containing an image
    /// - Returns: True if any text was found and sanitized
    func processImageForSensitiveText(_ item: ClipboardItem) -> Bool {
        // Only process images and only if the feature is enabled
        guard item.type == .image, 
              sanitizeImagesText, 
              let image = item.originalImage else {
            return false
        }
        
        // Extract text from the image
        guard let extractedText = ImageTextExtractor.extractText(from: image) else {
            return false
        }
        
        // If no text was found, nothing to do
        if extractedText.isEmpty {
            return false
        }
        
        // Check if the extracted text contains sensitive information
        let sanitizedText = sanitize(text: extractedText)
        
        // If the text was sanitized (changed), indicate this to the user
        if sanitizedText != extractedText {
            // Create a new image with a sensitive data indicator
            if let markedImage = SensitiveDataImageProcessor.addSensitiveDataMark(to: image) {
                item.originalImage = markedImage
            }
            return true
        }
        
        return false
    }
    
    // MARK: - Sanitization Helper Methods
    
    /// Masks text by replacing characters with asterisks
    /// - Parameter text: The text to mask
    /// - Returns: The masked text
    private func maskText(_ text: String) -> String {
        return String(repeating: "*", count: text.count)
    }
    
    /// Obfuscates text by creating a hash of it
    /// - Parameter text: The text to obfuscate
    /// - Returns: The obfuscated text
    private func obfuscateText(_ text: String) -> String {
        // Hash the text to create an obfuscated version
        if let data = text.data(using: .utf8) {
            let hashed = SHA256.hash(data: data)
            let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
            return "[OBFUSCATED:" + String(hashString.prefix(8)) + "]"
        }
        return "[OBFUSCATED]"
    }
    
    /// Calculates a confidence score for a potential sensitive data match
    /// - Parameters:
    ///   - text: The matched text
    ///   - pattern: The pattern that matched
    /// - Returns: A confidence score between 0.0 and 1.0
    private func calculateConfidence(text: String, pattern: SensitiveDataPattern) -> Double {
        var confidence = 0.5 // Base confidence
        
        // Adjust confidence based on pattern category
        switch pattern.category {
        case "Payment Information":
            // Credit card validation checks
            if pattern.name.contains("Credit Card") {
                // Basic Luhn algorithm validation for credit cards
                confidence = validateLuhnAlgorithm(text.filter { $0.isNumber }) ? 0.9 : 0.3
            }
        case "Government ID":
            // SSN pattern is very specific
            confidence = 0.85
        case "Credentials":
            // Most credentials are high risk
            confidence = 0.8
            
            // Check for common fake API keys or placeholders
            let fakeParts = ["example", "test", "sample", "dummy", "yourkey", "placeholder"]
            if fakeParts.contains(where: { text.lowercased().contains($0) }) {
                confidence = 0.2
            }
        case "Contact Information":
            // Email and phone validation
            if pattern.name.contains("Email") {
                confidence = text.contains("@") && text.contains(".") ? 0.75 : 0.3
            } else if pattern.name.contains("Phone") {
                confidence = text.filter { $0.isNumber }.count >= 10 ? 0.7 : 0.4
            }
        default:
            confidence = 0.6
        }
        
        // Adjust for context - lower confidence for very common short strings
        if text.count < 6 {
            confidence *= 0.8
        }
        
        return min(max(confidence, 0.0), 1.0) // Ensure between 0 and 1
    }
    
    /// Validates a number using the Luhn algorithm (for credit cards)
    /// - Parameter string: The numeric string to validate
    /// - Returns: True if the string passes the Luhn check
    private func validateLuhnAlgorithm(_ string: String) -> Bool {
        let digits = string.compactMap { Int(String($0)) }
        guard digits.count >= 13 && digits.count <= 19 else { return false }
        
        var sum = 0
        let alt = digits.reversed().enumerated().map { (i, d) -> Int in
            if i % 2 == 1 {
                let doubled = d * 2
                return doubled > 9 ? doubled - 9 : doubled
            }
            return d
        }
        
        sum = alt.reduce(0, +)
        return sum % 10 == 0
    }
    
    // MARK: - Rule Management Methods
    
    /// Adds a new sanitization rule
    /// - Parameter rule: The rule to add
    func addRule(_ rule: SanitizationRule) {
        if ruleDAO.save(rule) {
            rules.append(rule)
        }
    }
    
    /// Updates an existing sanitization rule
    /// - Parameter rule: The rule to update
    func updateRule(_ rule: SanitizationRule) {
        if ruleDAO.update(rule) {
            if let index = rules.firstIndex(where: { $0.id == rule.id }) {
                rules[index] = rule
            }
        }
    }
    
    /// Deletes a sanitization rule
    /// - Parameter rule: The rule to delete
    func deleteRule(_ rule: SanitizationRule) {
        if ruleDAO.delete(rule) {
            rules.removeAll { $0.id == rule.id }
        }
    }
    
    /// Toggles a rule's enabled state
    /// - Parameter rule: The rule to toggle
    func toggleRule(_ rule: SanitizationRule) {
        var updatedRule = rule
        updatedRule.isEnabled = !rule.isEnabled
        updateRule(updatedRule)
    }
    
    /// Resets to default sanitization rules
    func resetToDefaultRules() {
        // Clear existing rules
        ruleDAO.deleteAll()
        
        // Add default rules from factory
        let defaultRules = SanitizationRuleFactory.createDefaultRules()
        _ = ruleDAO.saveAll(defaultRules)
        
        // Update local array
        rules = defaultRules
    }
    
    // MARK: - Pattern Management Methods
    
    /// Adds a new sensitive data pattern
    /// - Parameter pattern: The pattern to add
    func addPattern(_ pattern: SensitiveDataPattern) {
        if patternDAO.save(pattern) {
            sensitivePatterns.append(pattern)
        }
    }
    
    /// Updates an existing sensitive data pattern
    /// - Parameter pattern: The pattern to update
    func updatePattern(_ pattern: SensitiveDataPattern) {
        if patternDAO.update(pattern) {
            if let index = sensitivePatterns.firstIndex(where: { $0.id == pattern.id }) {
                sensitivePatterns[index] = pattern
            }
        }
    }
    
    /// Deletes a sensitive data pattern
    /// - Parameter pattern: The pattern to delete
    func deletePattern(_ pattern: SensitiveDataPattern) {
        if patternDAO.delete(pattern) {
            sensitivePatterns.removeAll { $0.id == pattern.id }
        }
    }
    
    /// Resets to default sensitive data patterns
    func resetToDefaultPatterns() {
        // Clear existing patterns
        patternDAO.deleteAll()
        
        // Add default patterns from factory
        let defaultPatterns = SensitiveDataPatternFactory.createDefaultPatterns()
        _ = patternDAO.saveAll(defaultPatterns)
        
        // Update local array
        sensitivePatterns = defaultPatterns
    }
    
    // MARK: - Data Access Methods
    
    /// Loads sanitization rules from the database
    private func loadRules() {
        let dbRules = ruleDAO.getAll()
        
        if dbRules.isEmpty {
            // If no rules exist, create defaults
            let defaultRules = SanitizationRuleFactory.createDefaultRules()
            _ = ruleDAO.saveAll(defaultRules)
            rules = defaultRules
        } else {
            rules = dbRules
        }
    }
    
    /// Loads sensitive data patterns from the database
    private func loadPatterns() {
        let dbPatterns = patternDAO.getAll()
        
        if dbPatterns.isEmpty {
            // If no patterns exist, create defaults
            let defaultPatterns = SensitiveDataPatternFactory.createDefaultPatterns()
            _ = patternDAO.saveAll(defaultPatterns)
            sensitivePatterns = defaultPatterns
        } else {
            sensitivePatterns = dbPatterns
        }
    }
    
    /// Loads user preferences for sanitization
    private func loadPreferences() {
        detectionEnabled = UserDefaults.standard.bool(forKey: "sensitiveDataDetectionEnabled")
        sanitizeImagesText = UserDefaults.standard.bool(forKey: "sanitizeImagesText")
        
        // Set defaults if not previously set
        if UserDefaults.standard.object(forKey: "sensitiveDataDetectionEnabled") == nil {
            detectionEnabled = true
            UserDefaults.standard.set(true, forKey: "sensitiveDataDetectionEnabled")
        }
        
        if UserDefaults.standard.object(forKey: "sanitizeImagesText") == nil {
            sanitizeImagesText = true
            UserDefaults.standard.set(true, forKey: "sanitizeImagesText")
        }
    }
    
    /// Saves user preferences for sanitization
    func savePreferences() {
        UserDefaults.standard.set(detectionEnabled, forKey: "sensitiveDataDetectionEnabled")
        UserDefaults.standard.set(sanitizeImagesText, forKey: "sanitizeImagesText")
    }
    
    // MARK: - Import/Export Methods
    
    /// Exports all sanitization rules to a JSON file
    /// - Parameter completion: Callback with the result
    func exportRules(completion: @escaping (Result<URL, Error>) -> Void) {
        RuleImportExportService.shared.exportRules(rules, completion: completion)
    }
    
    /// Imports sanitization rules from a JSON file
    /// - Parameter url: The URL of the file to import
    /// - Returns: Result of the import operation
    func importRules(from url: URL) -> Result<Void, RuleImportError> {
        let result = RuleImportExportService.shared.importRules(from: url)
        
        switch result {
        case .success(let importedRules):
            // Clear existing rules and save imported ones
            ruleDAO.deleteAll()
            _ = ruleDAO.saveAll(importedRules)
            
            // Update local array
            rules = importedRules
            return .success(())
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Exports sensitive data patterns to a JSON file
    /// - Parameter completion: Callback with the result
    func exportPatterns(completion: @escaping (Result<URL, Error>) -> Void) {
        do {
            // Create a JSON encoder
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            // Encode the patterns
            let data = try encoder.encode(sensitivePatterns)
            
            // Get the export directory
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            // Create a unique filename
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateString = dateFormatter.string(from: Date())
            let exportURL = documentsURL.appendingPathComponent("ClipWizard_Patterns_\(dateString).json")
            
            // Write to file
            try data.write(to: exportURL)
            completion(.success(exportURL))
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Imports sensitive data patterns from a JSON file
    /// - Parameter url: The URL of the file to import
    /// - Returns: Result of the import operation
    func importPatterns(from url: URL) -> Result<Void, Error> {
        do {
            // Read the file data
            let data = try Data(contentsOf: url)
            
            // Create a JSON decoder
            let decoder = JSONDecoder()
            
            // Decode the patterns
            let importedPatterns = try decoder.decode([SensitiveDataPattern].self, from: data)
            
            // Check if we have valid patterns
            if importedPatterns.isEmpty {
                return .failure(NSError(domain: "com.clipwizard", code: 1002, 
                                     userInfo: [NSLocalizedDescriptionKey: "No valid patterns found in the file"]))
            }
            
            // Save the imported patterns
            patternDAO.deleteAll()
            _ = patternDAO.saveAll(importedPatterns)
            
            // Update local array
            sensitivePatterns = importedPatterns
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - Sensitive Data Detection Model

/// Represents a detected instance of sensitive data
struct SensitiveDataDetection {
    /// The pattern that detected this sensitive data
    let pattern: SensitiveDataPattern
    
    /// The matched text
    let matchedText: String
    
    /// The range of the matched text in the original string
    let range: Range<String.Index>
    
    /// Confidence level (0.0 to 1.0) that this is actually sensitive data
    let confidence: Double
}

// MARK: - Image Processing Utilities

/// Extracts text from images using OCR
class ImageTextExtractor {
    /// Extracts text from an image
    /// - Parameter image: The image to process
    /// - Returns: Extracted text, or nil if extraction failed
    static func extractText(from image: NSImage) -> String? {
        // This is a placeholder for actual OCR implementation
        // In a real implementation, this would use Vision framework or a third-party OCR library
        
        // For now, we'll simulate text extraction
        // In a real app, you would integrate with Vision framework for OCR
        
        // Simulate some basic OCR processing time
        Thread.sleep(forTimeInterval: 0.1)
        
        // Return nil to indicate no text was found
        // In a real implementation, this would return actual text from the image
        return nil
    }
}

/// Processes images for sensitive data indicators
class SensitiveDataImageProcessor {
    /// Adds a visual mark to indicate sensitive data in an image
    /// - Parameter image: The image to mark
    /// - Returns: The marked image
    static func addSensitiveDataMark(to image: NSImage) -> NSImage? {
        // Create a copy of the image to work with
        guard let copy = image.copy() as? NSImage else { return nil }
        
        // Create a new image context
        let size = copy.size
        let rect = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        
        // Draw the original image
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        copy.draw(in: rect)
        
        // Draw a warning overlay
        let overlayRect = NSRect(x: 10, y: 10, width: 120, height: 30)
        let overlayPath = NSBezierPath(roundedRect: overlayRect, xRadius: 5, yRadius: 5)
        NSColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 0.8).setFill()
        overlayPath.fill()
        
        // Add text to the overlay
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 10),
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraphStyle
        ]
        
        let text = "SENSITIVE DATA"
        let textRect = NSRect(x: 10, y: 15, width: 120, height: 20)
        text.draw(in: textRect, withAttributes: attributes)
        
        newImage.unlockFocus()
        return newImage
    }
}
