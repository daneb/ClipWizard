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
        HSplitView {
            // Sidebar
            VStack(spacing: 0) {
                List {
                    Button(action: { selectedTab = .general }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("General")
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                    .background(selectedTab == .general ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                    
                    Button(action: { selectedTab = .rules }) {
                        HStack {
                            Image(systemName: "shield")
                            Text("Sanitization Rules")
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                    .background(selectedTab == .rules ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                    
                    Button(action: { selectedTab = .hotkeys }) {
                        HStack {
                            Image(systemName: "keyboard")
                            Text("Hotkeys")
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                    .background(selectedTab == .hotkeys ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                    
                    Button(action: { selectedTab = .about }) {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("About")
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                    .background(selectedTab == .about ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                }
                .listStyle(.sidebar)
            }
            .frame(width: 200)
            
            // Content area
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
            .padding()
        }
        .frame(width: 800, height: 450)
        .onAppear {
            maxHistoryItems = UserDefaults.standard.integer(forKey: "maxHistoryItems")
            if maxHistoryItems == 0 {
                maxHistoryItems = 50 // Default value
            }
        }
    }
}

struct GeneralSettingsView: View {
    @Binding var maxHistoryItems: Int
    @Binding var monitoringEnabled: Bool
    var clipboardMonitor: ClipboardMonitor
    
    var body: some View {
        Form {
            Section(header: Text("Clipboard History").font(.headline)) {
                Stepper("Maximum history items: \(maxHistoryItems)", value: $maxHistoryItems, in: 10...200, step: 10)
                    .onChange(of: maxHistoryItems) { oldValue, newValue in
                        UserDefaults.standard.set(newValue, forKey: "maxHistoryItems")
                        clipboardMonitor.setMaxHistoryItems(newValue)
                    }
                
                Button("Clear Clipboard History") {
                    clipboardMonitor.clearHistory()
                }
                .foregroundColor(.red)
            }
            
            Section(header: Text("Monitoring").font(.headline)) {
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
            
            Section(header: Text("Launch Options").font(.headline)) {
                Toggle("Launch at login", isOn: .constant(false)) // TODO: Implement
                Toggle("Show in menu bar", isOn: .constant(true)) // TODO: Implement
            }
        }
        .padding()
    }
}

struct SanitizationRulesView: View {
    @ObservedObject var sanitizationService: SanitizationService
    @Binding var selectedRule: SanitizationRule?
    @Binding var isAddingNewRule: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Rules list
            VStack {
                List {
                    ForEach(sanitizationService.rules) { rule in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(rule.name)
                                    .font(.headline)
                                
                                Text(rule.pattern)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            if rule.isEnabled {
                                Text("Enabled")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .cornerRadius(4)
                            } else {
                                Text("Disabled")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.gray)
                                    .cornerRadius(4)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedRule = rule
                            isAddingNewRule = false
                        }
                        .padding(.vertical, 4)
                        .background(selectedRule?.id == rule.id ? Color.accentColor.opacity(0.1) : Color.clear)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            sanitizationService.deleteRule(sanitizationService.rules[index])
                        }
                        sanitizationService.saveRules()
                    }
                }
                
                HStack {
                    Button(action: {
                        isAddingNewRule = true
                        selectedRule = nil
                    }) {
                        Label("Add Rule", systemImage: "plus")
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        sanitizationService.resetToDefaultRules()
                        sanitizationService.saveRules()
                    }) {
                        Text("Reset to Defaults")
                    }
                }
                .padding()
            }
            .frame(width: 300)
            
            Divider()
            
            // Rule detail/edit view
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
            .padding()
        }
    }
}

struct RuleEditView: View {
    @ObservedObject var sanitizationService: SanitizationService
    @State private var ruleName: String
    @State private var pattern: String
    @State private var isEnabled: Bool
    @State private var ruleType: SanitizationRuleType
    @State private var replacementValue: String
    @State private var isTestingPattern: Bool = false
    @State private var testInput: String = ""
    @State private var testOutput: String = ""
    
    private var existingRule: SanitizationRule?
    
    @Binding var isAddingNewRule: Bool
    @Binding var selectedRule: SanitizationRule?
    
    // Initialize for a new rule
    init(sanitizationService: SanitizationService, isAddingNewRule: Binding<Bool>, selectedRule: Binding<SanitizationRule?>) {
        self.sanitizationService = sanitizationService
        _isAddingNewRule = isAddingNewRule
        _selectedRule = selectedRule
        
        _ruleName = State(initialValue: "")
        _pattern = State(initialValue: "")
        _isEnabled = State(initialValue: true)
        _ruleType = State(initialValue: .mask)
        _replacementValue = State(initialValue: "")
        
        self.existingRule = nil
    }
    
    // Initialize for an existing rule
    init(sanitizationService: SanitizationService, rule: SanitizationRule, isAddingNewRule: Binding<Bool>, selectedRule: Binding<SanitizationRule?>) {
        self.sanitizationService = sanitizationService
        _isAddingNewRule = isAddingNewRule
        _selectedRule = selectedRule
        
        _ruleName = State(initialValue: rule.name)
        _pattern = State(initialValue: rule.pattern)
        _isEnabled = State(initialValue: rule.isEnabled)
        _ruleType = State(initialValue: rule.ruleType)
        _replacementValue = State(initialValue: rule.replacementValue ?? "")
        
        self.existingRule = rule
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(isAddingNewRule ? "Add New Rule" : "Edit Rule")
                    .font(.headline)
                
                Form {
                    Section(header: Text("Rule Settings")) {
                        TextField("Rule Name", text: $ruleName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        VStack(alignment: .leading) {
                            Text("RegEx Pattern")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            TextEditor(text: $pattern)
                                .font(.body)
                                .frame(minHeight: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                        }
                        
                        Toggle("Enabled", isOn: $isEnabled)
                        
                        Picker("Rule Type", selection: $ruleType) {
                            Text("Mask").tag(SanitizationRuleType.mask)
                            Text("Rename").tag(SanitizationRuleType.rename)
                            Text("Obfuscate").tag(SanitizationRuleType.obfuscate)
                            Text("Remove").tag(SanitizationRuleType.remove)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        if ruleType == .rename {
                            TextField("Replacement Value", text: $replacementValue)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    Section(header: Text("Test Pattern")) {
                        Toggle("Test Pattern", isOn: $isTestingPattern)
                        
                        if isTestingPattern {
                            VStack(alignment: .leading) {
                                Text("Input Text")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                TextEditor(text: $testInput)
                                    .font(.body)
                                    .frame(minHeight: 60)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                    )
                                    .onChange(of: testInput) { oldValue, newValue in
                                        testPattern()
                                    }
                                    .onChange(of: pattern) { oldValue, newValue in
                                        testPattern()
                                    }
                                    .onChange(of: ruleType) { oldValue, newValue in
                                        testPattern()
                                    }
                                    .onChange(of: replacementValue) { oldValue, newValue in
                                        testPattern()
                                    }
                                
                                Text("Output Text")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text(testOutput)
                                    .font(.body)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(5)
                            }
                        }
                    }
                }
                
                HStack {
                    Button(action: {
                        if isAddingNewRule {
                            isAddingNewRule = false
                        } else {
                            selectedRule = nil
                        }
                    }) {
                        Text("Cancel")
                    }
                    
                    Spacer()
                    
                    if !isAddingNewRule && existingRule != nil {
                        Button(action: {
                            sanitizationService.toggleRule(existingRule!)
                            sanitizationService.saveRules()
                            isEnabled = !isEnabled
                        }) {
                            Text(isEnabled ? "Disable" : "Enable")
                        }
                    }
                    
                    Button(action: {
                        saveRule()
                    }) {
                        Text(isAddingNewRule ? "Add Rule" : "Save Changes")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(ruleName.isEmpty || pattern.isEmpty)
                }
            }
            .padding()
        }
    }
    
    private func testPattern() {
        guard !pattern.isEmpty && !testInput.isEmpty else {
            testOutput = ""
            return
        }
        
        // Create a temporary rule
        let tempRule = SanitizationRule(
            name: ruleName,
            pattern: pattern,
            isEnabled: true,
            ruleType: ruleType,
            replacementValue: replacementValue.isEmpty ? nil : replacementValue
        )
        
        // Create temporary service with just this rule
        let tempService = SanitizationService(rules: [tempRule])
        
        // Apply the rule
        testOutput = tempService.sanitize(text: testInput)
    }
    
    private func saveRule() {
        let replacementValueToSave = replacementValue.isEmpty ? nil : replacementValue
        
        if isAddingNewRule {
            // Create a new rule
            let newRule = SanitizationRule(
                name: ruleName,
                pattern: pattern,
                isEnabled: isEnabled,
                ruleType: ruleType,
                replacementValue: replacementValueToSave
            )
            
            sanitizationService.addRule(newRule)
            selectedRule = newRule
        } else if let existingRule = existingRule {
            // Update the existing rule
            let updatedRule = SanitizationRule(
                id: existingRule.id,
                name: ruleName,
                pattern: pattern,
                isEnabled: isEnabled,
                ruleType: ruleType,
                replacementValue: replacementValueToSave
            )
            
            sanitizationService.updateRule(updatedRule)
            selectedRule = updatedRule
        }
        
        sanitizationService.saveRules()
        isAddingNewRule = false
    }
}

struct HotkeysSettingsView: View {
    @State private var clipboardHistoryHotkeyString = "Command+Shift+V"
    @State private var enableMonitoringHotkeyString = "Command+Shift+E"
    
    var body: some View {
        Form {
            Section(header: Text("Keyboard Shortcuts").font(.headline)) {
                HStack {
                    Text("Show Clipboard History")
                    Spacer()
                    TextField("Hotkey", text: $clipboardHistoryHotkeyString)
                        .frame(width: 200)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                HStack {
                    Text("Enable/Disable Monitoring")
                    Spacer()
                    TextField("Hotkey", text: $enableMonitoringHotkeyString)
                        .frame(width: 200)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Text("Note: Hotkey customization is currently under development.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clipboard")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            Text("ClipWizard")
                .font(.largeTitle)
                .bold()
            
            Text("Version 1.0")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("A powerful clipboard manager for macOS")
                .multilineTextAlignment(.center)
            
            Divider()
            
            Text("ClipWizard monitors your clipboard activity and provides tools to sanitize sensitive information automatically. Perfect for developers, writers, and anyone who works with text frequently.")
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
            
            Text("Created with ❤️ by Your Name")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
