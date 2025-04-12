import Foundation
import SQLite3

/// Data Access Object for SensitiveDataPattern
class SensitiveDataPatternDAO {
    private let db = DatabaseManager.shared
    
    /// Saves a sensitive data pattern to the database
    /// - Parameter pattern: The SensitiveDataPattern to save
    /// - Returns: True if successful, false otherwise
    func save(_ pattern: SensitiveDataPattern) -> Bool {
        return db.performSync { [self] in
            let sql = """
            INSERT INTO sensitive_data_patterns (
                id, name, pattern, description, category, created
            ) VALUES (?, ?, ?, ?, ?, ?);
            """
            
            let parameters: [Any] = [
                pattern.id.uuidString,
                pattern.name,
                pattern.pattern,
                pattern.description,
                pattern.category,
                pattern.created.timeIntervalSince1970
            ]
            
            let result = db.execute(sql, parameters: parameters)
            return result != -1
        }
    }
    
    /// Updates an existing sensitive data pattern
    /// - Parameter pattern: The SensitiveDataPattern to update
    /// - Returns: True if successful, false otherwise
    func update(_ pattern: SensitiveDataPattern) -> Bool {
        return db.performSync { [self] in
            let sql = """
            UPDATE sensitive_data_patterns SET
                name = ?,
                pattern = ?,
                description = ?,
                category = ?,
                created = ?
            WHERE id = ?;
            """
            
            let parameters: [Any] = [
                pattern.name,
                pattern.pattern,
                pattern.description,
                pattern.category,
                pattern.created.timeIntervalSince1970,
                pattern.id.uuidString
            ]
            
            let result = db.execute(sql, parameters: parameters)
            return result != -1
        }
    }
    
    /// Deletes a sensitive data pattern
    /// - Parameter pattern: The SensitiveDataPattern to delete
    /// - Returns: True if successful, false otherwise
    func delete(_ pattern: SensitiveDataPattern) -> Bool {
        return db.performSync { [self] in
            let sql = "DELETE FROM sensitive_data_patterns WHERE id = ?;"
            let result = db.execute(sql, parameters: [pattern.id.uuidString])
            return result != -1
        }
    }
    
    /// Retrieves a sensitive data pattern by its ID
    /// - Parameter id: The ID of the pattern
    /// - Returns: The SensitiveDataPattern if found, nil otherwise
    func getById(_ id: UUID) -> SensitiveDataPattern? {
        return db.performSync { [self] in
            var pattern: SensitiveDataPattern? = nil
            
            let sql = "SELECT * FROM sensitive_data_patterns WHERE id = ?;"
            let _ = db.query(sql, parameters: [id.uuidString]) { statement in
                pattern = self.createPatternFromStatement(statement)
            }
            
            return pattern
        }
    }
    
    /// Retrieves all sensitive data patterns, optionally filtered by category
    /// - Parameter category: Optional category to filter by
    /// - Returns: Array of SensitiveDataPattern objects
    func getAll(category: String? = nil) -> [SensitiveDataPattern] {
        return db.performSync { [self] in
            var patterns: [SensitiveDataPattern] = []
            
            // Build the SQL query
            var sql = "SELECT * FROM sensitive_data_patterns"
            var parameters: [Any] = []
            
            // Add category filter if provided
            if let category = category {
                sql += " WHERE category = ?"
                parameters.append(category)
            }
            
            // Add sorting
            sql += " ORDER BY name ASC;"
            
            // Execute the query
            let _ = db.query(sql, parameters: parameters) { statement in
                if let pattern = self.createPatternFromStatement(statement) {
                    patterns.append(pattern)
                }
            }
            
            return patterns
        }
    }
    
    /// Retrieves all available categories
    /// - Returns: Array of category names
    func getAllCategories() -> [String] {
        return db.performSync { [self] in
            var categories: [String] = []
            
            let sql = "SELECT DISTINCT category FROM sensitive_data_patterns ORDER BY category ASC;"
            
            let _ = db.query(sql) { statement in
                if let categoryCString = sqlite3_column_text(statement, 0) {
                    let category = String(cString: categoryCString)
                    categories.append(category)
                }
            }
            
            return categories
        }
    }
    
    /// Saves multiple sensitive data patterns in a transaction
    /// - Parameter patterns: The array of SensitiveDataPattern objects to save
    /// - Returns: True if all patterns were saved successfully, false otherwise
    func saveAll(_ patterns: [SensitiveDataPattern]) -> Bool {
        return db.performSync { [self] in
            db.beginTransaction()
            
            var success = true
            for pattern in patterns {
                if !save(pattern) {
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
    
    /// Deletes all sensitive data patterns
    /// - Returns: True if successful, false otherwise
    func deleteAll() -> Bool {
        return db.performSync { [self] in
            let sql = "DELETE FROM sensitive_data_patterns;"
            let result = db.execute(sql)
            return result != -1
        }
    }
    
    /// Creates a SensitiveDataPattern from a SQLite statement
    /// - Parameter statement: The SQLite statement
    /// - Returns: The created SensitiveDataPattern, or nil if an error occurred
    private func createPatternFromStatement(_ statement: OpaquePointer) -> SensitiveDataPattern? {
        // Extract values from columns
        guard let idCString = sqlite3_column_text(statement, 0) else { return nil }
        let idString = String(cString: idCString)
        
        guard let id = UUID(uuidString: idString) else { return nil }
        
        guard let nameCString = sqlite3_column_text(statement, 1) else { return nil }
        let name = String(cString: nameCString)
        
        guard let patternCString = sqlite3_column_text(statement, 2) else { return nil }
        let pattern = String(cString: patternCString)
        
        var description = ""
        if let descriptionCString = sqlite3_column_text(statement, 3) {
            description = String(cString: descriptionCString)
        }
        
        guard let categoryCString = sqlite3_column_text(statement, 4) else { return nil }
        let category = String(cString: categoryCString)
        
        let createdTimestamp = sqlite3_column_double(statement, 5)
        let created = Date(timeIntervalSince1970: createdTimestamp)
        
        return SensitiveDataPattern(
            id: id,
            name: name,
            pattern: pattern,
            description: description,
            category: category,
            created: created
        )
    }
}
