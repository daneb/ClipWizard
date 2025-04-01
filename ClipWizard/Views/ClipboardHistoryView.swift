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
            .padding(8)
            .background(Color(.systemGray))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            if filteredHistory.isEmpty {
                VStack {
                    Spacer()
                    if searchText.isEmpty {
                        Text("No clipboard history")
                            .foregroundColor(.gray)
                    } else {
                        Text("No items match your search")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
            } else {
                List {
                    ForEach(filteredHistory) { item in
                        ClipboardItemRow(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedItem = item
                                showingDetailView = true
                            }
                            .contextMenu {
                                Button(action: {
                                    clipboardMonitor.copyToClipboard(item)
                                }) {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                                
                                Button(role: .destructive, action: {
                                    if let index = clipboardMonitor.clipboardHistory.firstIndex(where: { $0.id == item.id }) {
                                        clipboardMonitor.clipboardHistory.remove(at: index)
                                    }
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .sheet(isPresented: $showingDetailView) {
            if let item = selectedItem {
                ClipboardItemDetailView(item: item)
                    .frame(width: 400, height: 300)
            }
        }
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Icon based on content type
                Image(systemName: item.type == .text ? "doc.text" : "photo")
                    .foregroundColor(.blue)
                
                // Timestamp
                Text(formattedDate(item.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Sanitized indicator if applicable
                if item.type == .text && item.originalText != item.sanitizedText {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            
            // Content preview
            if item.type == .text {
                Text(item.sanitizedText ?? item.originalText ?? "")
                    .lineLimit(2)
                    .font(.callout)
            } else if item.type == .image, let image = item.originalImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 100)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return "Today, \(formatter.string(from: date))"
        } else if Calendar.current.isDateInYesterday(date) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday, \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }
}

struct ClipboardItemDetailView: View {
    let item: ClipboardItem
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with timestamp and type
            HStack {
                Image(systemName: item.type == .text ? "doc.text" : "photo")
                    .foregroundColor(.blue)
                
                Text(formattedDate(item.timestamp))
                    .font(.headline)
                
                Spacer()
                
                if item.type == .text && item.originalText != item.sanitizedText {
                    Label("Sanitized", systemImage: "shield.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if item.type == .text {
                        if item.originalText != item.sanitizedText {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sanitized Content:")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                
                                Text(item.sanitizedText ?? "")
                                    .textSelection(.enabled)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                
                                Text("Original Content:")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                
                                Text(item.originalText ?? "")
                                    .textSelection(.enabled)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                            }
                        } else {
                            Text(item.originalText ?? "")
                                .textSelection(.enabled)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                    } else if item.type == .image, let image = item.originalImage {
                        VStack(alignment: .center) {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(4)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            
            Divider()
            
            // Actions
            HStack {
                Button(action: {
                    // Copy to clipboard
                    if let monitor = item.typeErasedClipboardMonitor as? ClipboardMonitor {
                        monitor.copyToClipboard(item)
                    }
                }) {
                    Label("Copy to Clipboard", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
}
