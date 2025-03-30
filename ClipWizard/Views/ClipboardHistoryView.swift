import SwiftUI

struct ClipboardHistoryView: View {
    @ObservedObject var clipboardMonitor: ClipboardMonitor
    @State private var searchText = ""
    @State private var selectedItem: ClipboardItem?
    @State private var showingDetailView = false
    
    var filteredHistory: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardMonitor.clipboardHistory
        } else {
            return clipboardMonitor.clipboardHistory.filter { item in
                if item.type == .text {
                    return item.originalText?.localizedCaseInsensitiveContains(searchText) ?? false
                }
                return false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding()
            .background(Color(.textBackgroundColor))
            
            Divider()
            
            // History list
            if filteredHistory.isEmpty {
                VStack {
                    Spacer()
                    Text("No clipboard history")
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else {
                List {
                    ForEach(filteredHistory) { item in
                        ClipboardItemRow(item: item)
                            .onTapGesture {
                                clipboardMonitor.copyToClipboard(item)
                            }
                            .contextMenu {
                                Button(action: {
                                    clipboardMonitor.copyToClipboard(item)
                                }) {
                                    Text("Copy to Clipboard")
                                    Image(systemName: "doc.on.doc")
                                }
                                
                                Button(action: {
                                    selectedItem = item
                                    showingDetailView = true
                                }) {
                                    Text("View Details")
                                    Image(systemName: "info.circle")
                                }
                                
                                Divider()
                                
                                Button(action: {
                                    if let index = clipboardMonitor.clipboardHistory.firstIndex(of: item) {
                                        clipboardMonitor.clipboardHistory.remove(at: index)
                                    }
                                }) {
                                    Text("Delete")
                                    Image(systemName: "trash")
                                }
                            }
                    }
                }
                .listStyle(PlainListStyle())
            }
            
            Divider()
            
            // Bottom toolbar
            HStack {
                Button(action: {
                    clipboardMonitor.clearHistory()
                }) {
                    Text("Clear All")
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Spacer()
                
                Text("\(filteredHistory.count) items")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .frame(width: 350, height: 500)
        .sheet(isPresented: $showingDetailView) {
            if let item = selectedItem {
                ClipboardItemDetailView(item: item)
            }
        }
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Icon based on type
            if item.type == .image {
                Image(systemName: "photo")
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: "doc.text")
                    .frame(width: 20, height: 20)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Content preview
                if item.type == .text {
                    Text(item.sanitizedText ?? item.originalText ?? "")
                        .lineLimit(2)
                        .font(.body)
                } else if item.type == .image, let image = item.originalImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 60)
                }
                
                // Timestamp
                Text(timeAgoString(for: item.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Sanitized indicator
                if item.isSanitized {
                    Text("Sanitized")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func timeAgoString(for date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "Yesterday" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        } else {
            return "Just now"
        }
    }
}

struct ClipboardItemDetailView: View {
    let item: ClipboardItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Clipboard Item Details")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    NSApp.sendAction(#selector(NSPopover.close), to: nil, from: nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    // Type and timestamp
                    GroupBox(label: Text("Information").bold()) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Type:")
                                    .bold()
                                Text(item.type == .text ? "Text" : "Image")
                            }
                            
                            HStack {
                                Text("Copied at:")
                                    .bold()
                                Text(formattedDate(item.timestamp))
                            }
                            
                            if item.type == .text && item.isSanitized {
                                HStack {
                                    Text("Status:")
                                        .bold()
                                    Text("Sanitized")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    .padding(.horizontal)
                    
                    // Original content
                    if item.type == .text {
                        GroupBox(label: Text("Original Text").bold()) {
                            Text(item.originalText ?? "")
                                .padding(.vertical, 5)
                                .textSelection(.enabled)
                        }
                        .padding(.horizontal)
                        
                        // Sanitized content (if different)
                        if item.isSanitized {
                            GroupBox(label: Text("Sanitized Text").bold()) {
                                Text(item.sanitizedText ?? "")
                                    .padding(.vertical, 5)
                                    .textSelection(.enabled)
                            }
                            .padding(.horizontal)
                        }
                    } else if item.type == .image, let image = item.originalImage {
                        GroupBox(label: Text("Image").bold()) {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                                .padding(.vertical, 5)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.bottom)
            }
            
            // Action buttons
            HStack {
                Button(action: {
                    if let pasteboard = NSPasteboard.general.string(forType: .string) {
                        NSLog("Copy to clipboard: \(pasteboard)")
                    }
                }) {
                    Text("Copy to Clipboard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                if item.type == .text && item.isSanitized {
                    Button(action: {
                        if let original = item.originalText {
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(original, forType: .string)
                        }
                    }) {
                        Text("Copy Original")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .frame(width: 450, height: 500)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}
