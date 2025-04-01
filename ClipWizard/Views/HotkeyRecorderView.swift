import SwiftUI
import AppKit

struct HotkeyRecorderView: NSViewRepresentable {
    @Binding var keyCombo: (key: String, modifiers: String)
    
    func makeNSView(context: Context) -> HotkeyRecorderNSView {
        let view = HotkeyRecorderNSView()
        view.delegate = context.coordinator
        return view
    }
    
    func updateNSView(_ nsView: HotkeyRecorderNSView, context: Context) {
        // Nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, HotkeyRecorderDelegate {
        var parent: HotkeyRecorderView
        
        init(_ parent: HotkeyRecorderView) {
            self.parent = parent
        }
        
        func hotkeyRecorderDidRecord(key: String, modifiers: String) {
            parent.keyCombo = (key, modifiers)
        }
    }
}

protocol HotkeyRecorderDelegate: AnyObject {
    func hotkeyRecorderDidRecord(key: String, modifiers: String)
}

class HotkeyRecorderNSView: NSView {
    weak var delegate: HotkeyRecorderDelegate?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        let modifiers = getModifierStrings(from: event.modifierFlags)
        
        // Only record if we have at least one modifier
        if !modifiers.isEmpty {
            let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
            if !key.isEmpty {
                delegate?.hotkeyRecorderDidRecord(key: key, modifiers: modifiers.joined(separator: "+"))
            }
        }
    }
    
    private func getModifierStrings(from flags: NSEvent.ModifierFlags) -> [String] {
        var modifiers: [String] = []
        
        if flags.contains(.command) {
            modifiers.append("cmd")
        }
        if flags.contains(.option) {
            modifiers.append("opt")
        }
        if flags.contains(.control) {
            modifiers.append("ctrl")
        }
        if flags.contains(.shift) {
            modifiers.append("shift")
        }
        
        return modifiers
    }
    
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            self.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.1).cgColor
            self.layer?.cornerRadius = 8
        }
        return result
    }
    
    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result {
            self.layer?.backgroundColor = nil
        }
        return result
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Draw a border
        let borderRect = NSInsetRect(bounds, 0.5, 0.5)
        NSColor.controlAccentColor.withAlphaComponent(0.5).setStroke()
        NSBezierPath.defaultLineWidth = 1.0
        let path = NSBezierPath(roundedRect: borderRect, xRadius: 8, yRadius: 8)
        path.stroke()
    }
}
