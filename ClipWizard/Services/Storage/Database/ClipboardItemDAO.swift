import Foundation
import AppKit
import SQLite3

/// Data Access Object for ClipboardItem
class ClipboardItemDAO {
    private let db = DatabaseManager.shared
    
    /// Saves a clipboard item to the database
    /// - Parameter item: The ClipboardItem to save
    /// - Returns: True if successful, false otherwise
    func save(_ item: ClipboardItem) -> Bool {
        return db.performSync { [self] in
            let sql = """
            INSERT INTO clipboard_items (
                id, timestamp, content_type, original_text, sanitized_text, is_sanitized, image_reference, preview_text
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
            """
            
            let id = item.id.uuidString
            let timestamp = item.timestamp.timeIntervalSince1970
            let contentType = item.type.rawValue
            let isSanitized = item.isSanitized ? 1 : 0
            
            var imageReference: String? = nil
            
            // Handle image storage if this is an image item
            if item.type == .image, let image = item.originalImage {
                imageReference = FileStorageManager.shared.saveImage(image, withId: id)
            }
            
            // Create a preview text for image items
            var previewText: String? = nil
            if item.type == .image {
                previewText = "[Image copied at \(DateFormatter.localizedString(from: item.timestamp, dateStyle: .short, timeStyle: .short))]"
            }
            
            let parameters: [Any?] = [
                id,
                timestamp,
                contentType,
                item.originalText,
                item.sanitizedText,
                isSanitized,
                imageReference,
                previewText ?? item.originalText?.prefix(100)
            ]
            
            let result = db.execute(sql, parameters: parameters.map { $0 ?? NSNull() })
            return result != -1
        }
    }
    
    /// Updates an existing clipboard item
    /// - Parameter item: The ClipboardItem to update
    /// - Returns: True if successful, false otherwise
    func update(_ item: ClipboardItem) -> Bool {
        return db.performSync { [self] in
            let sql = """
            UPDATE clipboard_items SET
                timestamp = ?,
                content_type = ?,
                original_text = ?,
                sanitized_text = ?,
                is_sanitized = ?,
                image_reference = ?,
                preview_text = ?
            WHERE id = ?;
            """
            
            let id = item.id.uuidString
            let timestamp = item.timestamp.timeIntervalSince1970
            let contentType = item.type.rawValue
            let isSanitized = item.isSanitized ? 1 : 0
            
            var imageReference: String? = nil
            
            // Handle image update if needed
            if item.type == .image, let image = item.originalImage {
                imageReference = FileStorageManager.shared.saveImage(image, withId: id)
            }
            
            // Create a preview text for image items
            var previewText: String? = nil
            if item.type == .image {
                previewText = "[Image copied at \(DateFormatter.localizedString(from: item.timestamp, dateStyle: .short, timeStyle: .short))]"
            }
            
            let parameters: [Any?] = [
                timestamp,
                contentType,
                item.originalText,
                item.sanitizedText,
                isSanitized,
                imageReference,
                previewText ?? item.originalText?.prefix(100),
                id
            ]
            
            // Execute the update
            let result = db.execute(sql, parameters: parameters.map { $0 ?? NSNull() })
            return result != -1
        }
    }
    
    /// Deletes a clipboard item
    /// - Parameter item: The ClipboardItem to delete
    /// - Returns: True if successful, false otherwise
    func delete(_ item: ClipboardItem) -> Bool {
        return db.performSync { [self] in
            // Delete associated image file if this is an image item
            if item.type == .image {
                FileStorageManager.shared.deleteImage(withId: item.id.uuidString)
            }
            
            // Delete from database
            let sql = "DELETE FROM clipboard_items WHERE id = ?;"
            let result = db.execute(sql, parameters: [item.id.uuidString])
            return result != -1
        }
    }
    
    /// Retrieves a clipboard item by its ID
    /// - Parameter id: The ID of the clipboard item
    /// - Returns: The ClipboardItem if found, nil otherwise
    func getById(_ id: UUID) -> ClipboardItem? {
        return db.performSync { [self] in
            var item: ClipboardItem? = nil
            
            let sql = "SELECT * FROM clipboard_items WHERE id = ?;"
            let _ = db.query(sql, parameters: [id.uuidString]) { statement in
                item = self.createClipboardItemFromStatement(statement)
            }
            
            return item
        }
    }
    
    /// Retrieves all clipboard items, optionally filtered and sorted
    /// - Parameters:
    ///   - limit: Maximum number of items to retrieve
    ///   - offset: Number of items to skip
    ///   - searchText: Optional text to search for
    ///   - sortBy: Column to sort by (default: timestamp)
    ///   - ascending: Whether to sort in ascending order (default: false)
    /// - Returns: Array of ClipboardItem objects
    func getAll(limit: Int = 100, offset: Int = 0, searchText: String? = nil, sortBy: String = "timestamp", ascending: Bool = false) -> [ClipboardItem] {
        return db.performSync { [self] in
            var items: [ClipboardItem] = []
            
            // Build the SQL query
            var sql = "SELECT * FROM clipboard_items"
            var parameters: [Any] = []
            
            // Add search condition if search text is provided
            if let searchText = searchText, !searchText.isEmpty {
                sql += " WHERE original_text LIKE ? OR sanitized_text LIKE ? OR preview_text LIKE ?"
                let searchPattern = "%\(searchText)%"
                parameters.append(searchPattern)
                parameters.append(searchPattern)
                parameters.append(searchPattern)
            }
            
            // Add sorting
            sql += " ORDER BY \(sortBy) \(ascending ? "ASC" : "DESC")"
            
            // Add limit and offset
            sql += " LIMIT ? OFFSET ?;"
            parameters.append(limit)
            parameters.append(offset)
            
            // Execute the query
            let _ = db.query(sql, parameters: parameters) { statement in
                if let item = self.createClipboardItemFromStatement(statement) {
                    items.append(item)
                }
            }
            
            return items
        }
    }
    
    /// Counts the total number of clipboard items, optionally filtered
    /// - Parameter searchText: Optional text to search for
    /// - Returns: The count of clipboard items
    func count(searchText: String? = nil) -> Int {
        return db.performSync { [self] in
            var count = 0
            
            // Build the SQL query
            var sql = "SELECT COUNT(*) FROM clipboard_items"
            var parameters: [Any] = []
            
            // Add search condition if search text is provided
            if let searchText = searchText, !searchText.isEmpty {
                sql += " WHERE original_text LIKE ? OR sanitized_text LIKE ? OR preview_text LIKE ?"
                let searchPattern = "%\(searchText)%"
                parameters.append(searchPattern)
                parameters.append(searchPattern)
                parameters.append(searchPattern)
            }
            
            // Execute the query
            let _ = db.query(sql, parameters: parameters) { statement in
                count = Int(sqlite3_column_int(statement, 0))
            }
            
            return count
        }
    }
    
    /// Deletes all clipboard items
    /// - Returns: True if successful, false otherwise
    func deleteAll() -> Bool {
        return db.performSync { [self] in
            // Delete all image files
            FileStorageManager.shared.deleteAllImages()
            
            // Delete all records from the database
            let sql = "DELETE FROM clipboard_items;"
            let result = db.execute(sql)
            return result != -1
        }
    }
    
    /// Deletes all clipboard items older than the specified date
    /// - Parameter date: The cutoff date
    /// - Returns: True if successful, false otherwise
    func deleteItemsOlderThan(_ date: Date) -> Bool {
        return db.performSync { [self] in
            let timestamp = date.timeIntervalSince1970
            
            // First get IDs of image items to delete their associated files
            var imageIds: [String] = []
            let imageSql = "SELECT id FROM clipboard_items WHERE timestamp < ? AND content_type = ?;"
            let _ = db.query(imageSql, parameters: [timestamp, ClipboardItemType.image.rawValue]) { statement in
                if let idCString = sqlite3_column_text(statement, 0) {
                    let id = String(cString: idCString)
                    imageIds.append(id)
                }
            }
            
            // Delete associated image files
            for id in imageIds {
                FileStorageManager.shared.deleteImage(withId: id)
            }
            
            // Delete records from the database
            let sql = "DELETE FROM clipboard_items WHERE timestamp < ?;"
            let result = db.execute(sql, parameters: [timestamp])
            return result != -1
        }
    }
    
    /// Creates a ClipboardItem from a SQLite statement
    /// - Parameter statement: The SQLite statement
    /// - Returns: The created ClipboardItem, or nil if an error occurred
    private func createClipboardItemFromStatement(_ statement: OpaquePointer) -> ClipboardItem? {
        // Extract values from columns
        guard let idCString = sqlite3_column_text(statement, 0) else { return nil }
        let idString = String(cString: idCString)
        
        guard let id = UUID(uuidString: idString) else { return nil }
        
        let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))
        
        guard let contentTypeCString = sqlite3_column_text(statement, 2) else { return nil }
        let contentTypeString = String(cString: contentTypeCString)
        
        guard let type = ClipboardItemType(rawValue: contentTypeString) else { return nil }
        
        var originalText: String? = nil
        if let originalTextCString = sqlite3_column_text(statement, 3) {
            originalText = String(cString: originalTextCString)
        }
        
        var sanitizedText: String? = nil
        if let sanitizedTextCString = sqlite3_column_text(statement, 4) {
            sanitizedText = String(cString: sanitizedTextCString)
        }
        
        let isSanitized = sqlite3_column_int(statement, 5) != 0
        
        var imageReference: String? = nil
        if let imageRefCString = sqlite3_column_text(statement, 6) {
            imageReference = String(cString: imageRefCString)
        }
        
        // Create the item based on its type
        let item: ClipboardItem
        
        if type == .text {
            guard let text = originalText else { return nil }
            item = ClipboardItem(text: text, timestamp: timestamp)
            item.sanitizedText = sanitizedText
        } else if type == .image {
            guard let imageRef = imageReference,
                  let image = FileStorageManager.shared.loadImage(withId: idString) else {
                return nil
            }
            item = ClipboardItem(image: image, timestamp: timestamp)
        } else {
            // Unknown type
            return nil
        }
        
        return item
    }
}
