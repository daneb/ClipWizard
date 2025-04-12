import SwiftUI

struct StorageSettingsView: View {
    @State private var retentionPeriod: Int = 48
    @State private var maxHistoryItems: Int = 100
    @State private var storageStats: [String: Any] = [:]
    
    private let integrationHelper = StorageIntegrationHelper.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Content container with consistent padding
            VStack(alignment: .leading, spacing: 16) {
                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text("Storage Settings")
                        .font(.headline)
                        .padding(.bottom, 2)
                    
                    Text("SQLite-based storage system")
                        .font(.subheadline)
                    
                    Text("ClipWizard uses SQLite for efficient clipboard history storage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Storage Statistics
                storageStatsView
                
                Divider()
                
                // Configuration Options in ScrollView
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Retention Period
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Retention Period")
                                .font(.subheadline)
                            
                            Picker("", selection: $retentionPeriod) {
                                Text("None").tag(0)
                                Text("24 Hours").tag(24)
                                Text("48 Hours").tag(48)
                                Text("7 Days").tag(168)
                                Text("30 Days").tag(720)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: retentionPeriod) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "clipboardRetentionPeriodHours")
                            }
                            
                            Text("Automatically remove clipboard items older than the selected period")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 4)
                        
                        // Max History Items
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Maximum History Items")
                                .font(.subheadline)
                            
                            Slider(value: Binding(
                                get: { Double(maxHistoryItems) },
                                set: { maxHistoryItems = Int($0) }
                            ), in: 10...500, step: 10)
                            .onChange(of: maxHistoryItems) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "maxHistoryItems")
                                
                                // Update the clipboard monitor
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("maxHistoryItemsChanged"),
                                    object: nil,
                                    userInfo: ["maxItems": newValue]
                                )
                            }
                            
                            HStack {
                                Text("\(maxHistoryItems) items")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("More items = more storage used")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.bottom, 4)
                        
                        // Privacy Settings
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Privacy Settings")
                                .font(.subheadline)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Enable Sensitive Data Detection", isOn: Binding(
                                    get: { UserDefaults.standard.bool(forKey: "sensitiveDataDetectionEnabled") },
                                    set: { UserDefaults.standard.set($0, forKey: "sensitiveDataDetectionEnabled") }
                                ))
                                
                                Toggle("Scan Images for Sensitive Text", isOn: Binding(
                                    get: { UserDefaults.standard.bool(forKey: "sanitizeImagesText") },
                                    set: { UserDefaults.standard.set($0, forKey: "sanitizeImagesText") }
                                ))
                                
                                Toggle("Use Secure Deletion for Sensitive Data", isOn: Binding(
                                    get: { UserDefaults.standard.bool(forKey: "useSecureDeletion") },
                                    set: { UserDefaults.standard.set($0, forKey: "useSecureDeletion") }
                                ))
                            }
                            
                            Text("These settings help protect sensitive information in your clipboard")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        .padding(.bottom, 4)
                        
                        // Maintenance Options
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Maintenance")
                                .font(.subheadline)
                            
                            Button("Optimize Storage") {
                                performMaintenance()
                            }
                            .buttonStyle(.bordered)
                            
                            Text("Cleans up unused space and optimizes database performance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                }
            }
            .padding(16) // Main content padding
        }
        .onAppear {
            reloadSettings()
            updateStats()
        }
    }
    
    // Storage Statistics View
    private var storageStatsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Storage Statistics")
                .font(.subheadline)
                .padding(.bottom, 2)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Total Items:").bold()
                    Text("Text Items:")
                    Text("Image Items:")
                    Text("Last Cleanup:")
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(storageStats["totalItems"] as? Int ?? 0)")
                    Text("\(storageStats["textItems"] as? Int ?? 0)")
                    Text("\(storageStats["imageItems"] as? Int ?? 0)")
                    if let lastCleanup = storageStats["lastCleanupTime"] as? Date {
                        Text(lastCleanup, style: .relative)
                    } else {
                        Text("Never")
                    }
                }
            }
            .font(.caption)
            
            Button("Refresh Stats") {
                updateStats()
            }
            .buttonStyle(.borderless)
            .font(.caption)
            .foregroundColor(.accentColor)
            .padding(.top, 4)
        }
        .padding(12)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    private func reloadSettings() {
        // Load retention period
        let savedRetention = UserDefaults.standard.integer(forKey: "clipboardRetentionPeriodHours")
        retentionPeriod = savedRetention > 0 ? savedRetention : 48
        
        // If no retention period is set, initialize with default
        if UserDefaults.standard.object(forKey: "clipboardRetentionPeriodHours") == nil {
            UserDefaults.standard.set(retentionPeriod, forKey: "clipboardRetentionPeriodHours")
        }
        
        // Load max history items
        let savedMaxItems = UserDefaults.standard.integer(forKey: "maxHistoryItems")
        maxHistoryItems = savedMaxItems > 0 ? savedMaxItems : 100
        
        // If no max items setting is found, initialize with default
        if UserDefaults.standard.object(forKey: "maxHistoryItems") == nil {
            UserDefaults.standard.set(maxHistoryItems, forKey: "maxHistoryItems")
        }
    }
    
    private func updateStats() {
        // Get stats from the clipboard monitor
        if let clipboardMonitor = (integrationHelper.getClipboardMonitor() as? EnhancedClipboardMonitor) {
            storageStats = clipboardMonitor.getStorageStatistics()
        }
    }
    
    private func performMaintenance() {
        if let clipboardMonitor = (integrationHelper.getClipboardMonitor() as? EnhancedClipboardMonitor) {
            clipboardMonitor.performMaintenance()
            
            // Update stats after a short delay to give maintenance time to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                updateStats()
            }
        }
    }
}

// Preview provider
struct StorageSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        StorageSettingsView()
            .frame(width: 350)
    }
}
