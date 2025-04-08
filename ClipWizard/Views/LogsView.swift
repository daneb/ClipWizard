import SwiftUI

struct LogsView: View {
    @State private var logContent: String = ""
    @State private var filteredLogContent: String = ""
    @State private var isLoading: Bool = false
    @State private var isRefreshing: Bool = false
    @State private var logLevel: LogLevel = LoggingService.shared.logLevel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header section
            HStack(spacing: 10) {
                Text("Application Logs")
                    .font(.headline)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Log Level")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Picker("", selection: $logLevel) {
                        Text("Debug").tag(LogLevel.debug)
                        Text("Info").tag(LogLevel.info)
                        Text("Warning").tag(LogLevel.warning)
                        Text("Error").tag(LogLevel.error)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                    .onChange(of: logLevel) { oldValue, newValue in
                        LoggingService.shared.logLevel = newValue
                        logInfo("Log level changed to \(newValue.rawValue)")
                        filterLogsByLevel()
                    }
                }
            }
            
            // Log actions
            HStack(spacing: 12) {
                Button(action: refreshLogs) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isLoading)
                
                Button(action: viewLogsInEditor) {
                    Label("Open in Editor", systemImage: "square.and.pencil")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                Text("Log file: \(getLogFileName())")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            // Log content
            ZStack(alignment: .center) {
                ScrollView {
                    Text(filteredLogContent)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .textSelection(.enabled)  // Allow text selection
                }
                .background(Color(.textBackgroundColor).opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(4)
                
                if isLoading {
                    ProgressView("Loading logs...")
                        .padding()
                        .background(Color(.windowBackgroundColor).opacity(0.9))
                        .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .onAppear {
            refreshLogs()
        }
    }
    
    private func refreshLogs() {
        isLoading = true
        isRefreshing = true
        
        // Use a background thread to load log content
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let content = LoggingService.shared.getLogFileContent() ?? "No logs available."
            
            // Update the UI on the main thread
            DispatchQueue.main.async { [self] in
                logContent = content
                filterLogsByLevel() // Apply filtering
                isLoading = false
                isRefreshing = false
            }
        }
    }
    
    private func viewLogsInEditor() {
        if let logPath = LoggingService.shared.getLogFilePath() {
            NSWorkspace.shared.open(URL(fileURLWithPath: logPath))
        } else {
            // Show an error if we couldn't get the log path
            let alert = NSAlert()
            alert.messageText = "Cannot Access Logs"
            alert.informativeText = "Unable to access the application logs."
            alert.runModal()
        }
    }
    
    private func getLogFileName() -> String {
        if let logPath = LoggingService.shared.getLogFilePath() {
            return URL(fileURLWithPath: logPath).lastPathComponent
        } else {
            return "Unknown"
        }
    }
    
    private func filterLogsByLevel() {
        // Skip if logContent is empty
        if logContent.isEmpty {
            filteredLogContent = ""
            return
        }
        
        // Split log content into lines
        let lines = logContent.components(separatedBy: "\n")
        var filteredLines: [String] = []
        
        // Filter based on log level
        for line in lines {
            if shouldShowLogLine(line, forLevel: logLevel) {
                filteredLines.append(line)
            }
        }
        
        // Join filtered lines back into a string
        filteredLogContent = filteredLines.joined(separator: "\n")
    }
    
    private func shouldShowLogLine(_ line: String, forLevel level: LogLevel) -> Bool {
        // Default to showing the line if we can't determine level
        if line.isEmpty {
            return true
        }
        
        // Check if the line contains any log level indicator
        let containsDebug = line.contains("[DEBUG]")
        let containsInfo = line.contains("[INFO]")
        let containsWarning = line.contains("[WARNING]")
        let containsError = line.contains("[ERROR]")
        
        // If line doesn't have any level indicator, show it for all levels
        if !containsDebug && !containsInfo && !containsWarning && !containsError {
            return true
        }
        
        // Filter based on selected level
        switch level {
        case .debug:
            // Debug shows everything
            return true
        case .info:
            // Info shows info, warning, and error
            return containsInfo || containsWarning || containsError
        case .warning:
            // Warning shows warning and error
            return containsWarning || containsError
        case .error:
            // Error shows only error
            return containsError
        }
    }
}
