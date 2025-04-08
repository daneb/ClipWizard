import SwiftUI

struct AboutWindow: View {
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        VStack(spacing: 8) {
            // App icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [Color(red: 0.3, green: 0.3, blue: 0.4), Color(red: 0.2, green: 0.2, blue: 0.3)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 80, height: 80)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: [Color.blue.opacity(0.8), Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 40, height: 40)
                    .offset(x: 10, y: 0)
                
                Image(systemName: "clipboard")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.top, 8)
            
            // App name
            Text("ClipWizard")
                .font(.title2)
                .fontWeight(.bold)
            
            // Version
            Text("Version \(appVersion) (\(buildNumber))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer(minLength: 4)
            
            // Copyright
            Text("Copyright © 2023-2025 ClipWizard. All rights reserved.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
        // Use fixed size with min dimensions to prevent window resizing issues
        .frame(minWidth: 300, minHeight: 180)
        .fixedSize()
        // Add an onDisappear handler to help clean up resources
        .onDisappear {
            // This helps ensure SwiftUI view resources are properly released
            logInfo("AboutWindow view disappeared")
        }
    }
}

#Preview {
    AboutWindow()
}
