import SwiftUI

struct ContentView: View {
    @ObservedObject var sanitizationService: SanitizationService
    @ObservedObject var clipboardMonitor: ClipboardMonitor
    @State private var selectedTab: Int = 0
    
    init(sanitizationService: SanitizationService, clipboardMonitor: ClipboardMonitor) {
        self.sanitizationService = sanitizationService
        self.clipboardMonitor = clipboardMonitor
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            HStack(spacing: 0) {
                tabButton(title: "History", systemImage: "clock", tabIndex: 0)
                tabButton(title: "Settings", systemImage: "gear", tabIndex: 1)
            }
            .padding(.horizontal)
            .padding(.top)
            
            Divider()
                .padding(.horizontal)
            
            // Tab content
            ZStack {
                if selectedTab == 0 {
                    ClipboardHistoryView(clipboardMonitor: clipboardMonitor)
                        .transition(.opacity)
                } else {
                    SettingsView(sanitizationService: sanitizationService, clipboardMonitor: clipboardMonitor)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: selectedTab)
        }
        .frame(width: 400, height: 400)
    }
    
    // Custom tab button
    private func tabButton(title: String, systemImage: String, tabIndex: Int) -> some View {
        Button(action: {
            selectedTab = tabIndex
        }) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(selectedTab == tabIndex ? Color.accentColor.opacity(0.1) : Color.clear)
            .foregroundColor(selectedTab == tabIndex ? .accentColor : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView(
        sanitizationService: SanitizationService(),
        clipboardMonitor: ClipboardMonitor()
    )
}
