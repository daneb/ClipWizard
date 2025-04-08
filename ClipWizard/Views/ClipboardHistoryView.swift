import SwiftUI

// Extension to allow setting specific corners with cornerRadius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RectCorner: OptionSet {
    let rawValue: Int
    
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomRight = RectCorner(rawValue: 1 << 2)
    static let bottomLeft = RectCorner(rawValue: 1 << 3)
    
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomRight, .bottomLeft]
    static let top: RectCorner = [.topLeft, .topRight]
    static let bottom: RectCorner = [.bottomLeft, .bottomRight]
    static let left: RectCorner = [.topLeft, .bottomLeft]
    static let right: RectCorner = [.topRight, .bottomRight]
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topLeft = corners.contains(.topLeft)
        let topRight = corners.contains(.topRight)
        let bottomLeft = corners.contains(.bottomLeft)
        let bottomRight = corners.contains(.bottomRight)
        
        let width = rect.width
        let height = rect.height
        
        // Top left corner
        if topLeft {
            path.move(to: CGPoint(x: 0, y: radius))
            path.addArc(center: CGPoint(x: radius, y: radius),
                         radius: radius,
                         startAngle: .degrees(180),
                         endAngle: .degrees(270),
                         clockwise: false)
        } else {
            path.move(to: CGPoint(x: 0, y: 0))
        }
        
        // Top right corner
        if topRight {
            path.addLine(to: CGPoint(x: width - radius, y: 0))
            path.addArc(center: CGPoint(x: width - radius, y: radius),
                         radius: radius,
                         startAngle: .degrees(270),
                         endAngle: .degrees(0),
                         clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: width, y: 0))
        }
        
        // Bottom right corner
        if bottomRight {
            path.addLine(to: CGPoint(x: width, y: height - radius))
            path.addArc(center: CGPoint(x: width - radius, y: height - radius),
                         radius: radius,
                         startAngle: .degrees(0),
                         endAngle: .degrees(90),
                         clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: width, y: height))
        }
        
        // Bottom left corner
        if bottomLeft {
            path.addLine(to: CGPoint(x: radius, y: height))
            path.addArc(center: CGPoint(x: radius, y: height - radius),
                         radius: radius,
                         startAngle: .degrees(90),
                         endAngle: .degrees(180),
                         clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: 0, y: height))
        }
        
        path.closeSubpath()
        return path
    }
}

struct ClipboardHistoryView: View {
    @ObservedObject var clipboardMonitor: ClipboardMonitor
    @State private var searchText = ""
    @State private var selectedItem: ClipboardItem?
    @State private var showingDetailView = false
    @State private var hoveredItem: ClipboardItem?
    @State private var showingHoverPreview = false
    
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
        ZStack {
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
                    List(selection: $selectedItem) {
                        ForEach(filteredHistory) { item in
                            ClipboardItemRow(item: item, isSelected: selectedItem?.id == item.id)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if selectedItem?.id == item.id {
                                        // If already selected, show detail view
                                        showingDetailView = true
                                    } else {
                                        // Otherwise, just select it
                                        selectedItem = item
                                    }
                                }
                                .onHover { hovering in
                                    if hovering && item.type == .image {
                                        hoveredItem = item
                                        showingHoverPreview = true
                                    } else if !hovering && hoveredItem?.id == item.id {
                                        // Small delay to prevent flickering when moving between items
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            if hoveredItem?.id == item.id {
                                                showingHoverPreview = false
                                                hoveredItem = nil
                                            }
                                        }
                                    }
                                }
                                .contextMenu {
                                    Button(action: {
                                        clipboardMonitor.copyToClipboard(item)
                                    }) {
                                        Label("Copy", systemImage: "doc.on.doc")
                                    }
                                    
                                    Button(action: {
                                        selectedItem = item
                                        showingDetailView = true
                                    }) {
                                        Label("View Details", systemImage: "eye")
                                    }
                                    
                                    Button(role: .destructive, action: {
                                        if selectedItem?.id == item.id {
                                            selectedItem = nil
                                        }
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
                        .frame(width: 550, height: 500)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showingHoverPreview)
            
            // Bottom toolbar for actions when item is selected
            VStack {
                Spacer()
                
                if selectedItem != nil {
                    HStack(spacing: 16) {
                        Button(action: {
                            if let item = selectedItem {
                                clipboardMonitor.copyToClipboard(item)
                            }
                        }) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: {
                            showingDetailView = true
                        }) {
                            Label("Details", systemImage: "info.circle")
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button(role: .destructive, action: {
                            if let item = selectedItem, let index = clipboardMonitor.clipboardHistory.firstIndex(where: { $0.id == item.id }) {
                                clipboardMonitor.clipboardHistory.remove(at: index)
                                selectedItem = nil
                            }
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                    .padding(12)
                    .background(Color(.windowBackgroundColor).opacity(0.9))
                    .cornerRadius(12, corners: [.topLeft, .topRight])
                    .shadow(radius: 2, y: -2)
                    .transition(.move(edge: .bottom))
                }
            }
            .animation(.spring(), value: selectedItem != nil)
            
            // Fixed position image preview overlay - placed to the right side
            HStack {
                Spacer()
                
                if showingHoverPreview, let item = hoveredItem, item.type == .image, let nsImage = item.originalImage {
                    VStack {
                        Text("Preview")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.top, 4)
                        
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 200, maxHeight: 160)
                            .cornerRadius(8)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 4)
                        
                        // Add image dimensions
                        Text("\(Int(nsImage.size.width)) × \(Int(nsImage.size.height))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.windowBackgroundColor))
                            .shadow(radius: 5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                    )
                    .frame(width: 220)
                    .padding(.trailing, 20)
                    .transition(.opacity)
                }
            }
            .zIndex(100)
        }
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    var isSelected: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Selection indicator
            if isSelected {
                Color.accentColor
                    .frame(width: 4)
                    .frame(maxHeight: .infinity)
            } else {
                Color.clear
                    .frame(width: 4)
            }
            
            VStack(alignment: .leading, spacing: 6) {
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
                        Text("Sanitized")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
                
                // Content preview
                if item.type == .text {
                    Text(item.sanitizedText ?? item.originalText ?? "")
                        .lineLimit(2)
                        .font(.callout)
                        .foregroundColor(isSelected ? .primary : .secondary)
                } else if item.type == .image, let nsImage = item.originalImage {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 80)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        }
        .contentShape(Rectangle())
        .cornerRadius(6)
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
    @State private var zoomLevel: CGFloat = 1.0
    @State private var imagePosition: CGPoint = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with timestamp and type
            HStack {
                Image(systemName: item.type == .text ? "doc.text" : "photo")
                    .foregroundColor(.blue)
                
                Text(formattedDate(item.timestamp))
                    .font(.headline)
                
                Spacer()
                
                if item.type == .text && item.originalText != item.sanitizedText {
                    Label("Sanitized", systemImage: "shield.fill")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }
            .padding()
            .background(Color(.windowBackgroundColor).opacity(0.95))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if item.type == .text {
                        if item.originalText != item.sanitizedText {
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Sanitized Content")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                    
                                    Text(item.sanitizedText ?? "")
                                        .textSelection(.enabled)
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.textBackgroundColor))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                .padding(.horizontal)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Original Content")
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                    
                                    Text(item.originalText ?? "")
                                        .textSelection(.enabled)
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.textBackgroundColor))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Content")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                Text(item.originalText ?? "")
                                    .textSelection(.enabled)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.textBackgroundColor))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal)
                        }
                    } else if item.type == .image, let nsImage = item.originalImage {
                        // Image view with zoom controls
                        VStack(spacing: 12) {
                            // Zooming controls
                            HStack {
                                Button(action: {
                                    zoomLevel = max(0.25, zoomLevel - 0.25)
                                }) {
                                    Image(systemName: "minus.magnifyingglass")
                                }
                                
                                Slider(value: $zoomLevel, in: 0.25...3.0, step: 0.25)
                                    .frame(width: 150)
                                
                                Button(action: {
                                    zoomLevel = min(3.0, zoomLevel + 0.25)
                                }) {
                                    Image(systemName: "plus.magnifyingglass")
                                }
                                
                                Button(action: {
                                    zoomLevel = 1.0
                                    dragOffset = .zero
                                    imagePosition = .zero
                                }) {
                                    Image(systemName: "arrow.counterclockwise")
                                }
                            }
                            .padding(.horizontal)
                            
                            // Image with gesture support
                            ZStack {
                                Color.black.opacity(0.05)
                                    .cornerRadius(8)
                                
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .scaledToFit()
                                    .scaleEffect(zoomLevel)
                                    .offset(x: dragOffset.width, y: dragOffset.height)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                isDragging = true
                                                self.dragOffset = CGSize(
                                                    width: value.translation.width + self.imagePosition.x,
                                                    height: value.translation.height + self.imagePosition.y
                                                )
                                            }
                                            .onEnded { value in
                                                isDragging = false
                                                self.imagePosition = CGPoint(
                                                    x: value.translation.width + self.imagePosition.x,
                                                    y: value.translation.height + self.imagePosition.y
                                                )
                                                self.dragOffset = CGSize(
                                                    width: self.imagePosition.x,
                                                    height: self.imagePosition.y
                                                )
                                            }
                                    )
                            }
                            .frame(minHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
                            .padding(.horizontal)
                            
                            // Image metadata information
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Dimensions:")
                                        .fontWeight(.semibold)
                                    
                                    Text("\(Int(nsImage.size.width)) × \(Int(nsImage.size.height))")
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text("Zoom:")
                                        .fontWeight(.semibold)
                                    
                                    Text("\(Int(zoomLevel * 100))%")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        }
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
                
                if item.type == .image {
                    Button(action: {
                        // Save image to disk
                        saveImageToDisk()
                    }) {
                        Label("Save Image", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            .padding(12)
            .background(Color(.windowBackgroundColor).opacity(0.95))
        }
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    private func saveImageToDisk() {
        guard let nsImage = item.originalImage else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png, .jpeg]
        savePanel.nameFieldStringValue = "ClipWizard_Image_\(Int(Date().timeIntervalSince1970))"
        
        if savePanel.runModal() == .OK {
            if let url = savePanel.url {
                if let tiffData = nsImage.tiffRepresentation,
                   let bitmapImage = NSBitmapImageRep(data: tiffData),
                   let imageData = bitmapImage.representation(using: .png, properties: [:]) {
                    try? imageData.write(to: url)
                }
            }
        }
    }
}