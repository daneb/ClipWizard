import SwiftUI

struct SettingsView: View {
    @ObservedObject var sanitizationService: SanitizationService
    @ObservedObject var clipboardMonitor: ClipboardMonitor
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
                        HotkeysSettingsView()
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
                
                Toggle("Launch at login", isOn: .constant(false))
                Toggle("Show in menu bar", isOn: .constant(true))
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SanitizationRulesView: View {
    @ObservedObject var sanitizationService: SanitizationService
    @Binding var selectedRule: SanitizationRule?
    @Binding var isAddingNewRule: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Rules list and rule editor in vertical layout for popover
            VStack(spacing: 8) {
                // Rules header with action buttons
                HStack {
                    Text("Sanitization Rules")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        isAddingNewRule = true
                        selectedRule = nil
                    }) {
                        Label("Add", systemImage: "plus")
                    }
                    .buttonStyle(.borderless)
                    
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

struct HotkeysSettingsView: View {
    @State private var clipboardHistoryHotkeyString = "Command+Shift+V"
    @State private var enableMonitoringHotkeyString = "Command+Shift+E"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Keyboard Shortcuts")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Show Clipboard History")
                    Spacer()
                    TextField("Hotkey", text: $clipboardHistoryHotkeyString)
                        .frame(width: 150)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                HStack {
                    Text("Enable/Disable Monitoring")
                    Spacer()
                    TextField("Hotkey", text: $enableMonitoringHotkeyString)
                        .frame(width: 150)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            Text("Note: Hotkey customization is currently under development.")
                .font(.caption)
                .foregroundColor(.gray)
                
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

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
