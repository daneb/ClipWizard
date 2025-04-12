import Foundation
import SQLite3

/// Data Access Object for SanitizationRule
class SanitizationRuleDAO {
    private let db = DatabaseManager.shared
    
    /// Saves a sanitization rule to the database
    /// - Parameter rule: The SanitizationRule to save
    /// - Returns: True if successful, false otherwise
    func save(_ rule: SanitizationRule) -> Bool {
        return db.performSync { [self] in
            let sql = """
            INSERT INTO sanitization_rules (
                id, name, pattern, is_enabled, rule_type, replacement_value, priority
            ) VALUES (?, ?, ?, ?, ?, ?, ?);
            """
            
            // Convert rule type to integer for storage
            let ruleTypeInt: Int
            switch rule.ruleType {
            case .mask: ruleTypeInt = 0
            case .rename: ruleTypeInt = 1
            case .obfuscate: ruleTypeInt = 2
            case .remove: ruleTypeInt = 3
            }
            
            let parameters: [Any?] = [
                rule.id.uuidString,
                rule.name,
                rule.pattern,
                rule.isEnabled ? 1 : 0,
                ruleTypeInt,
                rule.replacementValue,
                rule.priority
            ]
            
            let result = db.execute(sql, parameters: parameters.map { $0 ?? NSNull() })
            return result != -1
        }
    }
    
    /// Updates an existing sanitization rule
    /// - Parameter rule: The SanitizationRule to update
    /// - Returns: True if successful, false otherwise
    func update(_ rule: SanitizationRule) -> Bool {
        return db.performSync { [self] in
            let sql = """
            UPDATE sanitization_rules SET
                name = ?,
                pattern = ?,
                is_enabled = ?,
                rule_type = ?,
                replacement_value = ?,
                priority = ?
            WHERE id = ?;
            """
            
            // Convert rule type to integer for storage
            let ruleTypeInt: Int
            switch rule.ruleType {
            case .mask: ruleTypeInt = 0
            case .rename: ruleTypeInt = 1
            case .obfuscate: ruleTypeInt = 2
            case .remove: ruleTypeInt = 3
            }
            
            let parameters: [Any?] = [
                rule.name,
                rule.pattern,
                rule.isEnabled ? 1 : 0,
                ruleTypeInt,
                rule.replacementValue,
                rule.priority,
                rule.id.uuidString
            ]
            
            let result = db.execute(sql, parameters: parameters.map { $0 ?? NSNull() })
            return result != -1
        }
    }
    
    /// Deletes a sanitization rule
    /// - Parameter rule: The SanitizationRule to delete
    /// - Returns: True if successful, false otherwise
    func delete(_ rule: SanitizationRule) -> Bool {
        return db.performSync { [self] in
            let sql = "DELETE FROM sanitization_rules WHERE id = ?;"
            let result = db.execute(sql, parameters: [rule.id.uuidString])
            return result != -1
        }
    }
    
    /// Retrieves a sanitization rule by its ID
    /// - Parameter id: The ID of the rule
    /// - Returns: The SanitizationRule if found, nil otherwise
    func getById(_ id: UUID) -> SanitizationRule? {
        return db.performSync { [self] in
            var rule: SanitizationRule? = nil
            
            let sql = "SELECT * FROM sanitization_rules WHERE id = ?;"
            let _ = db.query(sql, parameters: [id.uuidString]) { statement in
                rule = self.createRuleFromStatement(statement)
            }
            
            return rule
        }
    }
    
    /// Retrieves all sanitization rules, optionally filtered and sorted
    /// - Parameters:
    ///   - enabledOnly: Whether to only retrieve enabled rules
    ///   - sortBy: Column to sort by (default: priority)
    ///   - ascending: Whether to sort in ascending order (default: false)
    /// - Returns: Array of SanitizationRule objects
    func getAll(enabledOnly: Bool = false, sortBy: String = "priority", ascending: Bool = false) -> [SanitizationRule] {
        return db.performSync { [self] in
            var rules: [SanitizationRule] = []
            
            // Build the SQL query
            var sql = "SELECT * FROM sanitization_rules"
            var parameters: [Any] = []
            
            // Add filter for enabled rules if requested
            if enabledOnly {
                sql += " WHERE is_enabled = 1"
            }
            
            // Add sorting
            sql += " ORDER BY \(sortBy) \(ascending ? "ASC" : "DESC");"
            
            // Execute the query
            let _ = db.query(sql, parameters: parameters) { statement in
                if let rule = self.createRuleFromStatement(statement) {
                    rules.append(rule)
                }
            }
            
            return rules
        }
    }
    
    /// Saves multiple sanitization rules in a transaction
    /// - Parameter rules: The array of SanitizationRule objects to save
    /// - Returns: True if all rules were saved successfully, false otherwise
    func saveAll(_ rules: [SanitizationRule]) -> Bool {
        return db.performSync { [self] in
            db.beginTransaction()
            
            var success = true
            for rule in rules {
                if !save(rule) {
                    success = false
                    break
                }
            }
            
            if success {
                db.commitTransaction()
            } else {
                db.rollbackTransaction()
            }
            
            return success
        }
    }
    
    /// Deletes all sanitization rules
    /// - Returns: True if successful, false otherwise
    func deleteAll() -> Bool {
        return db.performSync { [self] in
            let sql = "DELETE FROM sanitization_rules;"
            let result = db.execute(sql)
            return result != -1
        }
    }
    
    /// Creates a SanitizationRule from a SQLite statement
    /// - Parameter statement: The SQLite statement
    /// - Returns: The created SanitizationRule, or nil if an error occurred
    private func createRuleFromStatement(_ statement: OpaquePointer) -> SanitizationRule? {
        // Extract values from columns
        guard let idCString = sqlite3_column_text(statement, 0) else { return nil }
        let idString = String(cString: idCString)
        
        guard let id = UUID(uuidString: idString) else { return nil }
        
        guard let nameCString = sqlite3_column_text(statement, 1) else { return nil }
        let name = String(cString: nameCString)
        
        guard let patternCString = sqlite3_column_text(statement, 2) else { return nil }
        let pattern = String(cString: patternCString)
        
        let isEnabled = sqlite3_column_int(statement, 3) != 0
        
        let ruleTypeInt = Int(sqlite3_column_int(statement, 4))
        
        var ruleType: SanitizationRuleType
        switch ruleTypeInt {
        case 0: ruleType = .mask
        case 1: ruleType = .rename
        case 2: ruleType = .obfuscate
        case 3: ruleType = .remove
        default: ruleType = .mask // Default to mask if unknown
        }
        
        var replacementValue: String? = nil
        if let replacementCString = sqlite3_column_text(statement, 5) {
            replacementValue = String(cString: replacementCString)
        }
        
        let priority = Int(sqlite3_column_int(statement, 6))
        
        return SanitizationRule(
            id: id,
            name: name,
            pattern: pattern,
            isEnabled: isEnabled,
            ruleType: ruleType,
            replacementValue: replacementValue,
            priority: priority
        )
    }
}
