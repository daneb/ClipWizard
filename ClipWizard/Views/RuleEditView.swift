import SwiftUI

struct RuleEditView: View {
    @ObservedObject var sanitizationService: SanitizationService
    @State private var ruleName: String
    @State private var pattern: String
    @State private var isEnabled: Bool
    @State private var ruleType: SanitizationRuleType
    @State private var replacementValue: String
    
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
        VStack(alignment: .leading, spacing: 10) {
            // Title
            Text(isAddingNewRule ? "Add New Rule" : "Edit Rule")
                .font(.headline)
            
            // Form fields
            TextField("Rule Name", text: $ruleName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text("RegEx Pattern")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                TextEditor(text: $pattern)
                    .font(.body)
                    .frame(height: 40)
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
            
            // Buttons
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
        .padding(.vertical)
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
