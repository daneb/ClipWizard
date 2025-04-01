import Foundation
import AppKit
import Carbon

class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()
    
    // Event handler id
    private var eventHandlerId: EventHandlerRef?
    
    // Registered hotkeys
    private var registeredHotkeys: [String: (UInt32, UInt32)] = [:]
    
    // Store hotkey combos for persistence
    private var hotkeyStrings: [String: (key: String, modifiers: String)] = [:]
    
    // Hotkey actions
    private var hotkeyActions: [String: () -> Void] = [:]
    
    private init() {
        setupEventHandler()
    }
    
    deinit {
        if let eventHandlerId = eventHandlerId {
            RemoveEventHandler(eventHandlerId)
        }
    }
    
    private func setupEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        
        // Install handler
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                let this = Unmanaged<HotkeyManager>.fromOpaque(userData!).takeUnretainedValue()
                return this.hotkeyEventHandler(event)
            },
            1,
            &eventType,
            selfPtr,
            &eventHandlerId
        )
        
        if status != noErr {
            print("Failed to install event handler: \(status)")
        }
    }
    
    private func hotkeyEventHandler(_ event: EventRef?) -> OSStatus {
        var hotkeyID: EventHotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotkeyID
        )
        
        if status == noErr {
            // Find the action for this hotkey ID
            for (key, (id, _)) in registeredHotkeys {
                if id == hotkeyID.id {
                    if let action = hotkeyActions[key] {
                        DispatchQueue.main.async {
                            action()
                        }
                    }
                    break
                }
            }
        }
        
        return status
    }
    
    func registerHotkey(
        id: String,
        keyCode: UInt32,
        modifiers: UInt32,
        action: @escaping () -> Void
    ) -> Bool {
        // Unregister existing hotkey with this ID if it exists
        unregisterHotkey(id: id)
        
        // Generate a unique ID for this hotkey
        let hotkeyID = UInt32(registeredHotkeys.count + 1)
        
        // Create the hotkey ID struct
        var hotKeyRef: EventHotKeyRef?
        var hotKeyID = EventHotKeyID(signature: OSType(0x434C4950), // "CLIP"
                                     id: hotkeyID)
        
        // Register the hotkey
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr && hotKeyRef != nil {
            registeredHotkeys[id] = (hotkeyID, modifiers)
            hotkeyActions[id] = action
            return true
        } else {
            print("Failed to register hotkey: \(status)")
            return false
        }
    }
    
    func unregisterHotkey(id: String) {
        guard let (hotkeyID, _) = registeredHotkeys[id] else { return }
        
        var hotKeyID = EventHotKeyID(signature: OSType(0x434C4950), id: hotkeyID)
        var hotKeyRef: EventHotKeyRef?
        
        // Find the hotkey reference
        let status = GetEventParameter(
            nil,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        
        if status == noErr {
            // Unregister the hotkey
            if let hotKeyRef = hotKeyRef {
                let unregisterStatus = UnregisterEventHotKey(hotKeyRef)
                if unregisterStatus != noErr {
                    print("Failed to unregister hotkey: \(unregisterStatus)")
                }
            }
        }
        
        // Remove from our dictionaries
        registeredHotkeys.removeValue(forKey: id)
        hotkeyActions.removeValue(forKey: id)
    }
    
    func unregisterAllHotkeys() {
        for id in registeredHotkeys.keys {
            unregisterHotkey(id: id)
        }
    }
    
    // Load hotkeys from UserDefaults
    func loadHotkeys() {
        if let savedHotkeys = UserDefaults.standard.dictionary(forKey: "savedHotkeys") as? [String: [String: String]] {
            for (id, combo) in savedHotkeys {
                if let key = combo["key"], let modifiersStr = combo["modifiers"],
                   let keyCode = HotkeyManager.keyCodeForCharacter(key) {
                    let modifiers = HotkeyManager.carbonModifierFlagsFromString(modifiersStr)
                    hotkeyStrings[id] = (key, modifiersStr)
                    
                    // Re-register the hotkey with action lookup
                    _ = registerHotkey(id: id, keyCode: keyCode, modifiers: modifiers, action: getActionForHotkey(id))
                }
            }
        }
    }
    
    // Save hotkeys to UserDefaults
    func saveHotkeys() {
        var hotkeyDict: [String: [String: String]] = [:]
        
        for (id, combo) in hotkeyStrings {
            hotkeyDict[id] = ["key": combo.key, "modifiers": combo.modifiers]
        }
        
        UserDefaults.standard.set(hotkeyDict, forKey: "savedHotkeys")
    }
    
    // Get the human-readable combo for a hotkey
    func getHotkeyCombo(for id: String) -> (key: String, modifiers: String)? {
        return hotkeyStrings[id]
    }
    
    // Register with string representation
    func registerHotkeyWithStrings(
        id: String,
        key: String,
        modifiers: String,
        action: @escaping () -> Void
    ) -> Bool {
        guard let keyCode = HotkeyManager.keyCodeForCharacter(key) else {
            return false
        }
        
        let modifierFlags = HotkeyManager.carbonModifierFlagsFromString(modifiers)
        let result = registerHotkey(id: id, keyCode: keyCode, modifiers: modifierFlags, action: action)
        
        if result {
            hotkeyStrings[id] = (key, modifiers)
            saveHotkeys()
        }
        
        return result
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

// Extension to convert string modifiers to Carbon modifiers
extension HotkeyManager {
    static func carbonModifierFlagsFromString(_ modifierString: String) -> UInt32 {
        var modifiers: UInt32 = 0
        
        if modifierString.contains("cmd") || modifierString.contains("command") {
            modifiers |= UInt32(cmdKey)
        }
        if modifierString.contains("opt") || modifierString.contains("option") || modifierString.contains("alt") {
            modifiers |= UInt32(optionKey)
        }
        if modifierString.contains("ctrl") || modifierString.contains("control") {
            modifiers |= UInt32(controlKey)
        }
        if modifierString.contains("shift") {
            modifiers |= UInt32(shiftKey)
        }
        
        return modifiers
    }
    
    static func keyCodeForCharacter(_ character: String) -> UInt32? {
        // Define a mapping from characters to key codes
        let keyCodeMap: [String: UInt32] = [
            "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7,
            "c": 8, "v": 9, "b": 11, "q": 12, "w": 13, "e": 14, "r": 15, "y": 16,
            "t": 17, "1": 18, "2": 19, "3": 20, "4": 21, "6": 22, "5": 23, "=": 24,
            "9": 25, "7": 26, "-": 27, "8": 28, "0": 29, "]": 30, "o": 31, "u": 32,
            "[": 33, "i": 34, "p": 35, "l": 37, "j": 38, "'": 39, "k": 40, ";": 41,
            "\\": 42, ",": 43, "/": 44, "n": 45, "m": 46, ".": 47, "`": 50, "space": 49
        ]
        
        // Return the key code for the character
        return keyCodeMap[character.lowercased()]
    }
}
