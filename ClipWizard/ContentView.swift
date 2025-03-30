import SwiftUI

struct ContentView: View {
    @StateObject private var sanitizationService = SanitizationService()
    @StateObject private var clipboardMonitor: ClipboardMonitor
    @State private var selectedTab: Int = 0
    
    init() {
        // Create the sanitization service first
        let service = SanitizationService()
        service.loadRules()
        
        // Load the clipboard monitor with the sanitization service
        let monitor = ClipboardMonitor(sanitizationService: service)
        
        // Initialize the state objects
        _sanitizationService = StateObject(wrappedValue: service)
        _clipboardMonitor = StateObject(wrappedValue: monitor)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ClipboardHistoryView(clipboardMonitor: clipboardMonitor)
                .tabItem {
                    Label("History", systemImage: "clock")
                }
                .tag(0)
            
            SettingsView(sanitizationService: sanitizationService, clipboardMonitor: clipboardMonitor)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(1)
        }
        .padding()
        .frame(width: 400, height: 500)
    }
}

#Preview {
    ContentView()
}
