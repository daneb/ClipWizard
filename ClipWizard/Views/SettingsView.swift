import SwiftUI

struct SettingsView: View {
    @ObservedObject var sanitizationService: SanitizationService
    @ObservedObject var clipboardMonitor: ClipboardMonitor
    @StateObject private var hotkeyManager = HotkeyManager.shared
    @State private var selectedTab: SettingsTab = .general
    @State private var maxHistoryItems: Int = 50
    @State private var monitoringEnabled: Bool = true
    @State private var selectedRule: SanitizationRule?
    @State private var isAddingNewRule: Bool = false
    
    enum SettingsTab {
        case general
        case rules
        case hotkeys
        case about
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Settings tabs
            HStack(spacing: 12) {
                // General tab
                settingTabButton(
                    title: "General", 
                    icon: "gear", 
                    isSelected: selectedTab == .general,
                    action: { selectedTab = .general }
                )
                
                // Rules tab
                settingTabButton(
                    title: "Rules", 
                    icon: "shield", 
                    isSelected: selectedTab == .rules,
                    action: { selectedTab = .rules }
                )
                
                // Hotkeys tab
                settingTabButton(
                    title: "Hotkeys", 
                    icon: "keyboard", 
                    isSelected: selectedTab == .hotkeys,
                    action: { selectedTab = .hotkeys }
                )
                
                // About tab
                settingTabButton(
                    title: "About", 
                    icon: "info.circle", 
                    isSelected: selectedTab == .about,
                    action: { selectedTab = .about }
                )
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Divider()
                .padding(.top, 8)
            
            // Content area
            ScrollView {
                VStack {
                    switch selectedTab {
                    case .general:
                        GeneralSettingsView(
                            maxHistoryItems: $maxHistoryItems,
                            monitoringEnabled: $monitoringEnabled,
                            clipboardMonitor: clipboardMonitor
                        )
                    case .rules:
                        SanitizationRulesView(
                            sanitizationService: sanitizationService,
                            selectedRule: $selectedRule,
                            isAddingNewRule: $isAddingNewRule
                        )
                    case .hotkeys:
                        HotkeysSettingsView(hotkeyManager: hotkeyManager)
                    case .about:
                        AboutView()
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            maxHistoryItems = UserDefaults.standard.integer(forKey: "maxHistoryItems")
            if maxHistoryItems == 0 {
                maxHistoryItems = 50 // Default value
            }
            
            monitoringEnabled = UserDefaults.standard.bool(forKey: "monitoringEnabled")
            if !UserDefaults.standard.contains(key: "monitoringEnabled") {
                monitoringEnabled = true // Default to true if not set
            }
        }
    }
    
    private func settingTabButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .foregroundColor(isSelected ? .accentColor : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GeneralSettingsView: View {
    @Binding var maxHistoryItems: Int
    @Binding var monitoringEnabled: Bool
    @State private var launchAtLoginEnabled: Bool = false
    var clipboardMonitor: ClipboardMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Clipboard History section
            VStack(alignment: .leading, spacing: 10) {
                Text("Clipboard History")
                    .font(.headline)
                
                Stepper("Maximum history items: \(maxHistoryItems)", value: $maxHistoryItems, in: 10...200, step: 10)
                    .onChange(of: maxHistoryItems) { oldValue, newValue in
                        UserDefaults.standard.set(newValue, forKey: "maxHistoryItems")
                        clipboardMonitor.setMaxHistoryItems(newValue)
                    }
                
                Button("Clear Clipboard History") {
                    clipboardMonitor.clearHistory()
                }
                .foregroundColor(.red)
                .buttonStyle(.bordered)
            }
            
            Divider()
            
            // Monitoring section
            VStack(alignment: .leading, spacing: 10) {
                Text("Monitoring")
                    .font(.headline)
                
                Toggle("Enable clipboard monitoring", isOn: $monitoringEnabled)
                    .onChange(of: monitoringEnabled) { oldValue, newValue in
                        if newValue {
                            clipboardMonitor.startMonitoring()
                        } else {
                            clipboardMonitor.stopMonitoring()
                        }
                        UserDefaults.standard.set(newValue, forKey: "monitoringEnabled")
                    }
                
                Text("When enabled, ClipWizard will automatically monitor and store clipboard activity.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Divider()
            
            // Launch Options section
            VStack(alignment: .leading, spacing: 10) {
                Text("Launch Options")
                    .font(.headline)
                
                Toggle("Launch at login", isOn: $launchAtLoginEnabled)
                    .onChange(of: launchAtLoginEnabled) { oldValue, newValue in
                        LaunchAtLoginService.shared.setEnabled(newValue)
                    }
                
                Toggle("Show in menu bar", isOn: .constant(true))
                    .disabled(true) // Always enabled for now
                
                Text("ClipWizard will always show in the menu bar.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            // Initialize launch at login toggle from actual status
            launchAtLoginEnabled = LaunchAtLoginService.shared.isEnabled()
        }
    }
}

struct SanitizationRulesView: View {
    @ObservedObject var sanitizationService: SanitizationService
    @Binding var selectedRule: SanitizationRule?
    @Binding var isAddingNewRule: Bool
    @State private var showingImportAlert = false
    @State private var importError: RuleImportError? = nil
    @State private var showingExportSuccessAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Rules list and rule editor in vertical layout for popover
            VStack(spacing: 8) {
                // Rules header with action buttons
                HStack {
                    Text("Sanitization Rules")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Import button
                    Button(action: importRules) {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderless)
                    
                    // Export button
                    Button(action: exportRules) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderless)
                    
                    // Add rule button
                    Button(action: {
                        isAddingNewRule = true
                        selectedRule = nil
                    }) {
                        Label("Add", systemImage: "plus")
                    }
                    .buttonStyle(.borderless)
                    
                    // Reset button
                    Button(action: {
                        sanitizationService.resetToDefaultRules()
                        sanitizationService.saveRules()
                    }) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.bottom, 4)
                
                // Rules list
                List {
                    ForEach(sanitizationService.rules) { rule in
                        RuleListRow(rule: rule, isSelected: selectedRule?.id == rule.id)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedRule = rule
                                isAddingNewRule = false
                            }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            sanitizationService.deleteRule(sanitizationService.rules[index])
                        }
                        sanitizationService.saveRules()
                    }
                }
                .listStyle(PlainListStyle())
                .frame(height: 120) // Fixed height for the rules list
                
                Divider()
                
                // Rule detail/editor area
                VStack {
                    if isAddingNewRule {
                        RuleEditView(
                            sanitizationService: sanitizationService,
                            isAddingNewRule: $isAddingNewRule,
                            selectedRule: $selectedRule
                        )
                    } else if let rule = selectedRule {
                        RuleEditView(
                            sanitizationService: sanitizationService,
                            rule: rule,
                            isAddingNewRule: $isAddingNewRule,
                            selectedRule: $selectedRule
                        )
                    } else {
                        VStack {
                            Spacer()
                            Text("Select a rule to edit or add a new rule")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                }
            }
        }
        .alert("Import Error", isPresented: $showingImportAlert, presenting: importError) { error in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.localizedDescription)
        }
        .alert("Export Successful", isPresented: $showingExportSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Rules have been successfully exported.")
        }
    }
    
    // Method to handle rules import
    private func importRules() {
        guard let url = sanitizationService.showImportOpenPanel() else { return }
        
        let result = sanitizationService.importRules(from: url)
        switch result {
        case .success:
            // Successfully imported rules, nothing to do
            break
        case .failure(let error):
            // Show error alert
            importError = error
            showingImportAlert = true
        }
    }
    
    // Method to handle rules export
    private func exportRules() {
        guard let saveURL = sanitizationService.showExportSavePanel() else { return }
        
        sanitizationService.exportRules { result in
            switch result {
            case .success(let tempURL):
                do {
                    // Copy from temp file to the user selected location
                    if FileManager.default.fileExists(atPath: saveURL.path) {
                        try FileManager.default.removeItem(at: saveURL)
                    }
                    try FileManager.default.copyItem(at: tempURL, to: saveURL)
                    
                    // Show success alert
                    DispatchQueue.main.async {
                        showingExportSuccessAlert = true
                    }
                } catch {
                    print("Error saving rules file: \(error)")
                }
            case .failure(let error):
                print("Error exporting rules: \(error)")
            }
        }
    }
}

struct RuleListRow: View {
    let rule: SanitizationRule
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name)
                    .fontWeight(isSelected ? .bold : .regular)
                
                Text(rule.pattern)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if rule.isEnabled {
                Text("On")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            } else {
                Text("Off")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.gray)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(4)
    }
}

// HotkeysSettingsView is now defined in HotkeysSettingsView.swift

struct AboutView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "clipboard")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            Text("ClipWizard")
                .font(.title)
                .bold()
            
            Text("Version 1.0")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("A powerful clipboard manager for macOS")
                .multilineTextAlignment(.center)
            
            Divider()
                .padding(.vertical, 10)
            
            Text("ClipWizard monitors your clipboard activity and provides tools to sanitize sensitive information automatically.")
                .multilineTextAlignment(.center)
                .font(.body)
                .padding(.horizontal)
            
            Spacer()
            
            Text("Created by Your Name")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
