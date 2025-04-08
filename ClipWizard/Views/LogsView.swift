import SwiftUI

struct LogsView: View {
    @State private var logContent: String = ""
    @State private var isLoading: Bool = false
    @State private var isRefreshing: Bool = false
    @State private var logLevel: LogLevel = LoggingService.shared.logLevel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header section
            HStack {
                Text("Application Logs")
                    .font(.headline)
                
                Spacer()
                
                Picker("Log Level", selection: $logLevel) {
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
                }
            }
            
            // Log actions
            HStack {
                Button(action: refreshLogs) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(isLoading)
                
                Button(action: viewLogsInEditor) {
                    Label("Open in Editor", systemImage: "square.and.pencil")
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                Text("Log location: \(LoggingService.shared.getLogFilePath() ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 200, alignment: .trailing)
            }
            
            // Log content
            ZStack(alignment: .center) {
                ScrollView {
                    Text(logContent)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(5)
                }
                .background(Color(.textBackgroundColor).opacity(0.5))
                .cornerRadius(4)
                
                if isLoading {
                    ProgressView("Loading logs...")
                        .padding()
                        .background(Color(.windowBackgroundColor).opacity(0.8))
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
        DispatchQueue.global(qos: .userInitiated).async {
            let content = LoggingService.shared.getLogFileContent() ?? "No logs available."
            
            // Update the UI on the main thread
            DispatchQueue.main.async {
                self.logContent = content
                self.isLoading = false
                self.isRefreshing = false
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
}
