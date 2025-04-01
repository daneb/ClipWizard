import SwiftUI

struct HotkeysSettingsView: View {
    @ObservedObject var hotkeyManager: HotkeyManager
    @State private var recordingHotkeyFor: String? = nil
    @State private var tempKeyCombo: (key: String, modifiers: String) = ("", "")
    
    // Defined hotkey actions
    private let hotkeyOptions = [
        "showClipboardHistory": "Show Clipboard History",
        "toggleMonitoring": "Toggle Clipboard Monitoring",
        "clearHistory": "Clear Clipboard History",
        "copyLastItem": "Copy Last Item"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Keyboard Shortcuts")
                        .font(.headline)
                    
                    Text("Configure keyboard shortcuts for quick access to ClipWizard functions.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.bottom, 8)
            
            Divider()
                .padding(.bottom, 8)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(hotkeyOptions.keys.sorted()), id: \.self) { key in
                        HotkeyRow(
                            label: hotkeyOptions[key] ?? "",
                            keyCombo: hotkeyManager.getHotkeyCombo(for: key),
                            isRecording: recordingHotkeyFor == key,
                            tempKeyCombo: tempKeyCombo,
                            recorderView: recordingHotkeyFor == key ? 
                                AnyView(HotkeyRecorderView(keyCombo: $tempKeyCombo)
                                    .frame(width: 120, height: 30)) : nil,
                            onRecord: {
                                // Start recording for this hotkey
                                recordingHotkeyFor = key
                                tempKeyCombo = ("", "")
                            },
                            onClear: {
                                // Clear this hotkey
                                hotkeyManager.unregisterHotkey(id: key)
                                hotkeyManager.saveHotkeys()
                            },
                            onSave: { keyCombo in
                                // Save the recorded hotkey
                                if !keyCombo.key.isEmpty {
                                    _ = hotkeyManager.registerHotkeyWithStrings(
                                        id: key,
                                        key: keyCombo.key,
                                        modifiers: keyCombo.modifiers,
                                        action: getActionForHotkey(key)
                                    )
                                }
                                
                                // Stop recording
                                recordingHotkeyFor = nil
                            },
                            onCancel: {
                                // Cancel recording
                                recordingHotkeyFor = nil
                            }
                        )
                    }
                }
                .padding(.vertical, 12)
            }
            .background(Color(.textBackgroundColor).opacity(0.2))
            .cornerRadius(12)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    // Get the appropriate action for each hotkey
    private func getActionForHotkey(_ key: String) -> () -> Void {
        switch key {
        case "showClipboardHistory":
            return { NotificationCenter.default.post(name: .showClipboardHistory, object: nil) }
        case "toggleMonitoring":
            return { NotificationCenter.default.post(name: .toggleClipboardMonitoring, object: nil) }
        case "clearHistory":
            return { NotificationCenter.default.post(name: .clearClipboardHistory, object: nil) }
        case "copyLastItem":
            return { NotificationCenter.default.post(name: .copyLastClipboardItem, object: nil) }
        default:
            return {}
        }
    }
}

// Row for a single hotkey setting
struct HotkeyRow: View {
    let label: String
    let keyCombo: (key: String, modifiers: String)?
    let isRecording: Bool
    let tempKeyCombo: (key: String, modifiers: String)
    let recorderView: AnyView?
    let onRecord: () -> Void
    let onClear: () -> Void
    let onSave: ((key: String, modifiers: String)) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Action label
            Text(label)
                .font(.body)
                .foregroundColor(.primary)
            
            // Key combo and controls
            HStack {
                // Left side - shortcut display
                if isRecording {
                    // Recording mode
                    if let recorderView = recorderView {
                        recorderView
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.accentColor, lineWidth: 1)
                            )
                    } else if !tempKeyCombo.key.isEmpty {
                        Text(formattedKeyCombo(tempKeyCombo))
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        Text("Press keys...")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.accentColor, lineWidth: 1)
                            )
                    }
                } else {
                    // Normal mode - show current shortcut
                    if let combo = keyCombo, !combo.key.isEmpty {
                        Text(formattedKeyCombo(combo))
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        Text("None")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Spacer(minLength: 10)
                
                // Right side - action buttons
                HStack(spacing: 10) {
                    if isRecording {
                        // Recording mode buttons
                        if !tempKeyCombo.key.isEmpty {
                            Button(action: {
                                onSave(tempKeyCombo)
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 18))
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        
                        Button(action: {
                            onCancel()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 18))
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    } else {
                        // Normal mode buttons
                        if let combo = keyCombo, !combo.key.isEmpty {
                            Button(action: {
                                onClear()
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        
                        Button(action: {
                            onRecord()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "record.circle")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 14))
                                Text("Record")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
        .padding(10)
        .background(isRecording ? Color.accentColor.opacity(0.05) : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isRecording ? Color.accentColor.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }
    
    // Format key combo for display
    private func formattedKeyCombo(_ combo: (key: String, modifiers: String)) -> String {
        var result = ""
        
        if combo.modifiers.contains("cmd") || combo.modifiers.contains("command") {
            result += "⌘"
        }
        if combo.modifiers.contains("opt") || combo.modifiers.contains("option") || combo.modifiers.contains("alt") {
            result += "⌥"
        }
        if combo.modifiers.contains("ctrl") || combo.modifiers.contains("control") {
            result += "⌃"
        }
        if combo.modifiers.contains("shift") {
            result += "⇧"
        }
        
        if !combo.key.isEmpty {
            result += combo.key.uppercased()
        }
        
        return result
    }
}

#Preview {
    HotkeysSettingsView(hotkeyManager: HotkeyManager.shared)
}
