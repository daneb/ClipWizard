import Foundation
import SwiftUI

class RuleImportExportService {
    static let shared = RuleImportExportService()
    
    private init() {}
    
    // MARK: - Rule Export
    
    /// Export rules to a JSON file
    func exportRules(_ rules: [SanitizationRule], completion: @escaping (Result<URL, Error>) -> Void) {
        // Create a rules container with metadata
        let rulesContainer = RulesContainer(
            metadata: RulesMetadata(
                version: "1.0",
                exportDate: Date(),
                appName: "ClipWizard"
            ),
            rules: rules
        )
        
        do {
            // Convert to JSON data
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(rulesContainer)
            
            // Create a temporary file URL
            let temporaryDirectory = FileManager.default.temporaryDirectory
            let fileName = "ClipWizard_Rules_\(dateFormatter.string(from: Date())).json"
            let fileURL = temporaryDirectory.appendingPathComponent(fileName)
            
            // Write data to the file
            try jsonData.write(to: fileURL)
            
            // Return the URL for the caller to handle file saving dialog
            completion(.success(fileURL))
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Rule Import
    
    /// Import rules from a JSON file
    func importRules(from url: URL) -> Result<[SanitizationRule], RuleImportError> {
        do {
            // Read file data
            let data = try Data(contentsOf: url)
            
            // Try to decode as RulesContainer first
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                let rulesContainer = try decoder.decode(RulesContainer.self, from: data)
                return .success(rulesContainer.rules)
            } catch {
                // If that fails, try to decode as an array of SanitizationRules directly
                // This provides backward compatibility with older export formats
                do {
                    let rules = try decoder.decode([SanitizationRule].self, from: data)
                    return .success(rules)
                } catch {
                    return .failure(.invalidFormat)
                }
            }
        } catch {
            return .failure(.fileAccessError)
        }
    }
    
    // MARK: - File Panel Handling
    
    /// Show save panel for exporting rules
    func showSavePanel(suggestedFileName: String) -> URL? {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = false
        savePanel.nameFieldStringValue = suggestedFileName
        savePanel.allowedContentTypes = [.json]
        
        let response = savePanel.runModal()
        return response == .OK ? savePanel.url : nil
    }
    
    /// Show open panel for importing rules
    func showOpenPanel() -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [.json]
        
        let response = openPanel.runModal()
        return response == .OK ? openPanel.url : nil
    }
    
    // MARK: - Helper Properties
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()
}

// MARK: - Data Structures

/// Container for rules and metadata
struct RulesContainer: Codable {
    let metadata: RulesMetadata
    let rules: [SanitizationRule]
}

/// Metadata for rules export
struct RulesMetadata: Codable {
    let version: String
    let exportDate: Date
    let appName: String
}

/// Errors that can occur during rule import
enum RuleImportError: Error, LocalizedError {
    case fileAccessError
    case invalidFormat
    case incompatibleVersion
    
    var errorDescription: String? {
        switch self {
        case .fileAccessError:
            return "Could not access the rules file."
        case .invalidFormat:
            return "The file is not in a valid ClipWizard rules format."
        case .incompatibleVersion:
            return "The rules file version is not compatible with this version of ClipWizard."
        }
    }
}
