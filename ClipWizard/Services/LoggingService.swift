import Foundation

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

class LoggingService {
    static let shared = LoggingService()
    
    private let fileManager = FileManager.default
    private let dateFormatter: DateFormatter
    private var logFileURL: URL?
    private let logQueue = DispatchQueue(label: "com.clipwizard.logging", qos: .utility)
    private var logStream: OutputStream?
    
    var logLevel: LogLevel = .info // Default log level
    
    private init() {
        // Setup date formatter for timestamps
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        // Initialize log file
        setupLogFile()
    }
    
    private func setupLogFile() {
        // Get app support directory
        guard let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("Failed to get application support directory")
            return
        }
        
        // Create ClipWizard directory if it doesn't exist
        let clipWizardDir = appSupportDir.appendingPathComponent("ClipWizard", isDirectory: true)
        if !fileManager.fileExists(atPath: clipWizardDir.path) {
            do {
                try fileManager.createDirectory(at: clipWizardDir, withIntermediateDirectories: true)
            } catch {
                print("Failed to create ClipWizard directory: \(error)")
                return
            }
        }
        
        // Generate log file name based on date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        
        // Create log file URL
        logFileURL = clipWizardDir.appendingPathComponent("clipwizard_\(dateString).log")
        
        // Make sure the file exists
        if let url = logFileURL, !fileManager.fileExists(atPath: url.path) {
            fileManager.createFile(atPath: url.path, contents: nil)
        }
        
        // Set up output stream to the log file
        if let url = logFileURL {
            logStream = OutputStream(url: url, append: true)
            logStream?.open()
        }
        
        // Log the service start
        log(.info, message: "Logging service initialized")
        info("Log file location: \(logFileURL?.path ?? "unknown")")
    }
    
    private func log(_ level: LogLevel, message: String, file: String = #file, function: String = #function, line: Int = #line) {
        // Skip logs below the current log level
        guard shouldLog(level) else { return }
        
        // Get timestamp
        let timestamp = dateFormatter.string(from: Date())
        
        // Get the filename from the full path
        let filename = URL(fileURLWithPath: file).lastPathComponent
        
        // Create the log entry
        let logEntry = "\(timestamp) \(level.emoji) [\(level.rawValue)] [\(filename):\(line) \(function)] \(message)\n"
        
        // Write to the file on a background queue
        logQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Print to console for debugging purposes
            print(logEntry, terminator: "")
            
            // Write to the log file
            if let logStream = self.logStream, let data = logEntry.data(using: .utf8) {
                let bytes = [UInt8](data)
                logStream.write(bytes, maxLength: bytes.count)
            }
        }
    }
    
    private func shouldLog(_ level: LogLevel) -> Bool {
        switch (logLevel, level) {
        case (.debug, _): return true
        case (.info, .info), (.info, .warning), (.info, .error): return true
        case (.warning, .warning), (.warning, .error): return true
        case (.error, .error): return true
        default: return false
        }
    }
    
    // Public logging methods
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message: message, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message: message, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message: message, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message: message, file: file, function: function, line: line)
    }
    
    // Cleanup on app termination
    func shutdown() {
        log(.info, message: "Logging service shutting down")
        logStream?.close()
    }
    
    // Utility method to get the log file path (useful for sharing logs)
    func getLogFilePath() -> String? {
        return logFileURL?.path
    }
    
    // Utility method to read the current log file content
    func getLogFileContent() -> String? {
        guard let url = logFileURL else { return nil }
        
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("Error reading log file: \(error)")
            return nil
        }
    }
}

// Convenience global functions for easier logging throughout the app
func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    LoggingService.shared.debug(message, file: file, function: function, line: line)
}

func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    LoggingService.shared.info(message, file: file, function: function, line: line)
}

func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    LoggingService.shared.warning(message, file: file, function: function, line: line)
}

func logError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    LoggingService.shared.error(message, file: file, function: function, line: line)
}
