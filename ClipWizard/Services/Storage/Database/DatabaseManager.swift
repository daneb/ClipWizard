import Foundation
import SQLite3

// Extension to check if we're on a specific queue
extension DispatchQueue {
    // A key used to store a specific value in the queue's specific data
    private static let key = DispatchSpecificKey<UUID>()
    
    /// Initialize the specific data for queue identification
    fileprivate func setSpecific() {
        let uuid = UUID()
        setSpecific(key: DispatchQueue.key, value: uuid)
    }
    
    /// Check if the current thread is executing on this queue
    var isCurrent: Bool {
        // Get the specific value
        let queueID = getSpecific(key: DispatchQueue.key)
        
        // Check if the current queue's ID matches this queue's ID
        let currentID = DispatchQueue.getSpecific(key: DispatchQueue.key)
        return queueID != nil && queueID == currentID
    }
}

/// DatabaseManager is responsible for managing the SQLite database connection and operations
class DatabaseManager {
    static let shared = DatabaseManager()
    
    private var db: OpaquePointer?
    private let databasePath: String
    
    // Queue for serializing database operations
    private let dbQueue = DispatchQueue(label: "com.clipwizard.database", qos: .background)
    
    // Singleton initialization to ensure only one database connection
    private init() {
        // Set up the queue for identification
        dbQueue.setSpecific()
        
        // Create a directory for our app data if it doesn't exist
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirURL = appSupportURL.appendingPathComponent("ClipWizard", isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: appDirURL, withIntermediateDirectories: true)
        } catch {
            logError("Failed to create app directory: \(error.localizedDescription)")
        }
        
        // Set the database path
        databasePath = appDirURL.appendingPathComponent("clipwizard.sqlite").path
        
        // Open database connection
        openDatabase()
        
        // Create tables if they don't exist
        createTables()
    }
    
    /// Opens a connection to the SQLite database
    private func openDatabase() {
        if sqlite3_open(databasePath, &db) != SQLITE_OK {
            logError("Error opening database: \(String(describing: sqlite3_errmsg(db)))")
            return
        }
        logInfo("Successfully opened database connection at: \(databasePath)")
    }
    
    /// Creates the necessary database tables if they don't exist
    private func createTables() {
        // Create clipboard_items table
        let createClipboardItemsTableSQL = """
        CREATE TABLE IF NOT EXISTS clipboard_items (
            id TEXT PRIMARY KEY,
            timestamp REAL NOT NULL,
            content_type TEXT NOT NULL,
            original_text TEXT,
            sanitized_text TEXT,
            is_sanitized INTEGER NOT NULL DEFAULT 0,
            image_reference TEXT,
            preview_text TEXT
        );
        """
        
        // Create sanitization_rules table
        let createSanitizationRulesTableSQL = """
        CREATE TABLE IF NOT EXISTS sanitization_rules (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            pattern TEXT NOT NULL,
            is_enabled INTEGER NOT NULL DEFAULT 1,
            rule_type INTEGER NOT NULL,
            replacement_value TEXT,
            priority INTEGER NOT NULL DEFAULT 0
        );
        """
        
        // Create sensitive_data_patterns table
        let createSensitiveDataPatternsTableSQL = """
        CREATE TABLE IF NOT EXISTS sensitive_data_patterns (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            pattern TEXT NOT NULL,
            description TEXT,
            category TEXT NOT NULL,
            created REAL NOT NULL
        );
        """
        
        // Execute the SQL statements in a transaction
        dbQueue.sync {
            var errorMessage: String?
            
            if !executeSQL(createClipboardItemsTableSQL) { 
                errorMessage = "Failed to create clipboard_items table"
            } else if !executeSQL(createSanitizationRulesTableSQL) {
                errorMessage = "Failed to create sanitization_rules table"
            } else if !executeSQL(createSensitiveDataPatternsTableSQL) {
                errorMessage = "Failed to create sensitive_data_patterns table"
            }
            
            // Create indexes for performance
            let createTimestampIndexSQL = "CREATE INDEX IF NOT EXISTS idx_clipboard_items_timestamp ON clipboard_items(timestamp);"
            let createRulePatternIndexSQL = "CREATE INDEX IF NOT EXISTS idx_sanitization_rules_pattern ON sanitization_rules(pattern);"
            let createPatternsCategoryIndexSQL = "CREATE INDEX IF NOT EXISTS idx_sensitive_data_patterns_category ON sensitive_data_patterns(category);"
            
            if errorMessage == nil {
                if !executeSQL(createTimestampIndexSQL) {
                    errorMessage = "Failed to create timestamp index"
                } else if !executeSQL(createRulePatternIndexSQL) {
                    errorMessage = "Failed to create rule pattern index"
                } else if !executeSQL(createPatternsCategoryIndexSQL) {
                    errorMessage = "Failed to create patterns category index"
                }
            }
            
            if let error = errorMessage {
                logError(error)
            } else {
                logInfo("Successfully created database tables and indexes")
            }
        }
    }
    
    /// Executes a SQL statement
    /// - Parameter sql: The SQL statement to execute
    /// - Returns: True if successful, false if an error occurred
    private func executeSQL(_ sql: String) -> Bool {
        var statement: OpaquePointer?
        
        // Prepare the statement
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            logError("Error preparing statement: \(String(describing: sqlite3_errmsg(db)))")
            return false
        }
        
        // Execute the statement
        if sqlite3_step(statement) != SQLITE_DONE {
            logError("Error executing statement: \(String(describing: sqlite3_errmsg(db)))")
            sqlite3_finalize(statement)
            return false
        }
        
        // Finalize the statement
        sqlite3_finalize(statement)
        return true
    }
    
    /// Begins a database transaction
    func beginTransaction() -> Bool {
        return executeSQL("BEGIN TRANSACTION;")
    }
    
    /// Commits a database transaction
    func commitTransaction() -> Bool {
        return executeSQL("COMMIT TRANSACTION;")
    }
    
    /// Rolls back a database transaction
    func rollbackTransaction() -> Bool {
        return executeSQL("ROLLBACK TRANSACTION;")
    }
    
    /// Executes a query and calls the row handler for each row
    /// - Parameters:
    ///   - sql: The SQL query to execute
    ///   - parameters: Optional array of parameters to bind to the query
    ///   - rowHandler: A closure that processes each row
    /// - Returns: True if successful, false if an error occurred
    func query(_ sql: String, parameters: [Any]? = nil, rowHandler: (OpaquePointer) -> Void) -> Bool {
        var statement: OpaquePointer?
        
        // Prepare the statement
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            logError("Error preparing query: \(String(describing: sqlite3_errmsg(db)))")
            return false
        }
        
        // Bind parameters if any
        if let params = parameters {
            for (index, param) in params.enumerated() {
                let paramIndex = Int32(index + 1)
                
                switch param {
                case let value as Int:
                    sqlite3_bind_int(statement, paramIndex, Int32(value))
                case let value as Double:
                    sqlite3_bind_double(statement, paramIndex, value)
                case let value as String:
                    sqlite3_bind_text(statement, paramIndex, (value as NSString).utf8String, -1, nil)
                case let value as Data:
                    sqlite3_bind_blob(statement, paramIndex, (value as NSData).bytes, Int32(value.count), nil)
                case let value as Bool:
                    sqlite3_bind_int(statement, paramIndex, value ? 1 : 0)
                case is NSNull:
                    sqlite3_bind_null(statement, paramIndex)
                default:
                    let stringValue = String(describing: param)
                    sqlite3_bind_text(statement, paramIndex, (stringValue as NSString).utf8String, -1, nil)
                }
            }
        }
        
        // Execute the query and process each row
        while sqlite3_step(statement) == SQLITE_ROW {
            rowHandler(statement!)
        }
        
        // Check for errors
        if sqlite3_errcode(db) != SQLITE_DONE && sqlite3_errcode(db) != SQLITE_ROW {
            logError("Error during query: \(String(describing: sqlite3_errmsg(db)))")
            sqlite3_finalize(statement)
            return false
        }
        
        // Finalize the statement
        sqlite3_finalize(statement)
        return true
    }
    
    /// Executes an insert, update, or delete statement
    /// - Parameters:
    ///   - sql: The SQL statement to execute
    ///   - parameters: Optional array of parameters to bind to the statement
    /// - Returns: The ID of the last inserted row, or -1 if not an insert or error
    func execute(_ sql: String, parameters: [Any]? = nil) -> Int64 {
        var statement: OpaquePointer?
        
        // Prepare the statement
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            logError("Error preparing statement: \(String(describing: sqlite3_errmsg(db)))")
            return -1
        }
        
        // Bind parameters if any
        if let params = parameters {
            for (index, param) in params.enumerated() {
                let paramIndex = Int32(index + 1)
                
                switch param {
                case let value as Int:
                    sqlite3_bind_int(statement, paramIndex, Int32(value))
                case let value as Double:
                    sqlite3_bind_double(statement, paramIndex, value)
                case let value as String:
                    sqlite3_bind_text(statement, paramIndex, (value as NSString).utf8String, -1, nil)
                case let value as Data:
                    sqlite3_bind_blob(statement, paramIndex, (value as NSData).bytes, Int32(value.count), nil)
                case let value as Bool:
                    sqlite3_bind_int(statement, paramIndex, value ? 1 : 0)
                case is NSNull:
                    sqlite3_bind_null(statement, paramIndex)
                default:
                    let stringValue = String(describing: param)
                    sqlite3_bind_text(statement, paramIndex, (stringValue as NSString).utf8String, -1, nil)
                }
            }
        }
        
        // Execute the statement
        if sqlite3_step(statement) != SQLITE_DONE {
            logError("Error executing statement: \(String(describing: sqlite3_errmsg(db)))")
            sqlite3_finalize(statement)
            return -1
        }
        
        // Get the ID of the last inserted row if this was an insert
        let lastInsertRowId = sqlite3_last_insert_rowid(db)
        
        // Finalize the statement
        sqlite3_finalize(statement)
        
        return lastInsertRowId
    }
    
    /// Performs a database operation on the database queue
    /// - Parameter operation: The operation to perform
    func perform(_ operation: @escaping () -> Void) {
        dbQueue.async {
            operation()
        }
    }
    
    /// Performs a synchronous database operation on the database queue
    /// - Parameter operation: The operation to perform
    /// - Returns: The result of the operation
    func performSync<T>(_ operation: @escaping () -> T) -> T {
        // If we're already on the database queue, execute directly to avoid deadlock
        if dbQueue.isCurrent {
            return operation()
        }
        
        // Otherwise, perform synchronously on the queue
        return dbQueue.sync {
            return operation()
        }
    }
    
    /// Closes the database connection
    func closeDatabase() {
        sqlite3_close(db)
        db = nil
    }
    
    /// Deletes all data from all tables
    func clearAllData() -> Bool {
        let tables = ["clipboard_items", "sanitization_rules", "sensitive_data_patterns"]
        
        return dbQueue.sync {
            beginTransaction()
            
            var success = true
            for table in tables {
                if !executeSQL("DELETE FROM \(table);") {
                    success = false
                    break
                }
            }
            
            if success {
                commitTransaction()
            } else {
                rollbackTransaction()
            }
            
            return success
        }
    }
    
    /// Vacuum the database to reclaim unused space
    func vacuum() -> Bool {
        return executeSQL("VACUUM;")
    }
}
