import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers

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
            
            // Floating image preview overlay
            ImagePreviewOverlay(hoveredItem: hoveredItem, showingHoverPreview: showingHoverPreview)
                .zIndex(100)
        }
    }
}

// MARK: - Image Preview Overlay

// Separate component for the image preview overlay to reduce complexity
struct ImagePreviewOverlay: View {
    let hoveredItem: ClipboardItem?
    let showingHoverPreview: Bool
    
    var body: some View {
        GeometryReader { geometry in
            if showingHoverPreview, 
               let item = hoveredItem, 
               item.type == .image, 
               let nsImage = item.originalImage {
                
                // Calculate position
                let position = calculatePreviewPosition(geometry: geometry)
                
                // Preview content
                previewContent(nsImage: nsImage, position: position.point, width: position.width)
            }
        }
    }
    
    private func calculatePreviewPosition(geometry: GeometryProxy) -> (point: CGPoint, width: CGFloat) {
        let previewWidth: CGFloat = 220
        let previewHeight: CGFloat = 220
        
        // Get current mouse location
        let mouseLocation: NSPoint = NSEvent.mouseLocation
        let windowLocation: NSPoint = NSApp.mainWindow?.frame.origin ?? .zero
        let screenHeight: CGFloat = NSScreen.main?.frame.height ?? 800
        
        // Convert screen coordinates to view coordinates
        let relativeX: CGFloat = mouseLocation.x - windowLocation.x
        // Invert the y-axis because macOS screen coordinates start from bottom
        let relativeY: CGFloat = screenHeight - mouseLocation.y - windowLocation.y
        
        // Calculate optimal position for the preview
        let spaceRight: CGFloat = geometry.size.width - relativeX
        let spaceLeft: CGFloat = relativeX
        
        // Position horizontally based on available space
        let positionFromRight: Bool = spaceRight < previewWidth + 40
        let xOffset: CGFloat = positionFromRight ? spaceLeft - previewWidth - 20 : relativeX + 20
        
        // Ensure preview stays within the visible area
        let xPosition: CGFloat = max(20, min(xOffset, geometry.size.width - previewWidth - 20))
        
        // Calculate a good Y position, keeping preview in view
        let maxY: CGFloat = geometry.size.height - previewHeight - 20
        let minY: CGFloat = 20
        let yPosition: CGFloat = max(minY, min(relativeY - previewHeight/2, maxY))
        
        return (CGPoint(x: xPosition, y: yPosition), previewWidth)
    }
    
    // Extracted method to simplify the body
    @ViewBuilder
    private func previewContent(nsImage: NSImage, position: CGPoint, width: CGFloat) -> some View {
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
        .frame(width: width)
        .position(position)
        .transition(.opacity)
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
    
    // OCR state
    @State private var recognizedText: String = ""
    @State private var isPerformingOCR: Bool = false
    
    // Image manipulation states
    @State private var isShowingImageTools: Bool = false
    @State private var rotationAngle: Double = 0.0
    @State private var brightness: Double = 0.0
    @State private var contrast: Double = 1.0
    @State private var currentFilter: ImageFilter = .none
    @State private var modifiedImage: NSImage? = nil
    
    // Image format state
    @State private var selectedExportFormat: ExportFormat = .png
    
    // Image information
    @State private var fileSize: String = "Unknown"
    
    enum ImageFilter: String, CaseIterable, Identifiable {
        case none = "None"
        case grayscale = "Grayscale"
        case sepia = "Sepia"
        case invert = "Invert"
        case blur = "Blur"
        case sharpen = "Sharpen"
        
        var id: String { rawValue }
    }
    
    enum ExportFormat: String, CaseIterable, Identifiable {
        case png = "PNG"
        case jpeg = "JPEG"
        case tiff = "TIFF"
        case bmp = "BMP"
        
        var id: String { rawValue }
        
        var fileExtension: String {
            switch self {
            case .png: return "png"
            case .jpeg: return "jpg"
            case .tiff: return "tiff"
            case .bmp: return "bmp"
            }
        }
        
        var uniformTypeIdentifier: UTType {
            switch self {
            case .png: return UTType.png
            case .jpeg: return UTType.jpeg
            case .tiff: return UTType.tiff  
            case .bmp: return UTType.bmp
            }
        }
    }
    
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
                        // Image view with enhanced features
                        VStack(spacing: 8) {
                            // Tab view for different image functions
                            Picker("View Mode", selection: $isShowingImageTools) {
                                Text("Preview").tag(false)
                                Text("Edit").tag(true)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                            
                            Divider()
                            
                            if !isShowingImageTools {
                                // Standard preview mode with zoom controls
                                VStack(spacing: 10) {
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
                                        
                                        Image(nsImage: modifiedImage ?? nsImage)
                                            .resizable()
                                            .scaledToFit()
                                            .scaleEffect(zoomLevel)
                                            .rotationEffect(.degrees(rotationAngle))
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
                                    .frame(minHeight: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
                                    .padding(.horizontal)
                                    
                                    // Enhanced image metadata information
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 20) {
                                            VStack(alignment: .leading) {
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
                                            
                                            VStack(alignment: .leading) {
                                                HStack {
                                                    Text("File Size:")
                                                        .fontWeight(.semibold)
                                                    
                                                    Text(fileSize)
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                if rotationAngle != 0 {
                                                    HStack {
                                                        Text("Rotation:")
                                                            .fontWeight(.semibold)
                                                        
                                                        Text("\(Int(rotationAngle))°")
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                            }
                                        }
                                        
                                        if !recognizedText.isEmpty {
                                            Divider()
                                                .padding(.vertical, 4)
                                            
                                            HStack(alignment: .top) {
                                                Text("OCR Text:")
                                                    .fontWeight(.semibold)
                                                
                                                Text(recognizedText)
                                                    .foregroundColor(.secondary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .lineLimit(4)
                                            }
                                        }
                                    }
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                }
                            } else {
                                // Image editing tools
                                ScrollView {
                                    VStack(spacing: 16) {
                                        // Preview of edited image
                                        Image(nsImage: modifiedImage ?? nsImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 180)
                                            .cornerRadius(8)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
                                            .rotationEffect(.degrees(rotationAngle))
                                        
                                        // Rotation controls
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Rotation")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            HStack {
                                                Button(action: {
                                                    rotateImage(by: -90)
                                                }) {
                                                    Image(systemName: "rotate.left")
                                                }
                                                
                                                Slider(value: $rotationAngle, in: 0...360, step: 1)
                                                    .onChange(of: rotationAngle) { newValue in
                                                        applyImageAdjustments()
                                                    }
                                                
                                                Button(action: {
                                                    rotateImage(by: 90)
                                                }) {
                                                    Image(systemName: "rotate.right")
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                        
                                        // Brightness and contrast
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Adjustments")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            HStack {
                                                Text("Brightness")
                                                    .frame(width: 80, alignment: .leading)
                                                
                                                Slider(value: $brightness, in: -0.5...0.5, step: 0.05)
                                                    .onChange(of: brightness) { newValue in
                                                        applyImageAdjustments()
                                                    }
                                                
                                                Button(action: {
                                                    brightness = 0
                                                    applyImageAdjustments()
                                                }) {
                                                    Image(systemName: "arrow.counterclockwise")
                                                        .font(.caption)
                                                }
                                                .buttonStyle(BorderlessButtonStyle())
                                            }
                                            
                                            HStack {
                                                Text("Contrast")
                                                    .frame(width: 80, alignment: .leading)
                                                
                                                Slider(value: $contrast, in: 0.5...1.5, step: 0.05)
                                                    .onChange(of: contrast) { newValue in
                                                        applyImageAdjustments()
                                                    }
                                                
                                                Button(action: {
                                                    contrast = 1.0
                                                    applyImageAdjustments()
                                                }) {
                                                    Image(systemName: "arrow.counterclockwise")
                                                        .font(.caption)
                                                }
                                                .buttonStyle(BorderlessButtonStyle())
                                            }
                                        }
                                        .padding(.horizontal)
                                        
                                        // Filters
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Filters")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            Picker("Filter", selection: $currentFilter) {
                                                ForEach(ImageFilter.allCases) { filter in
                                                    Text(filter.rawValue).tag(filter)
                                                }
                                            }
                                            .pickerStyle(SegmentedPickerStyle())
                                            .onChange(of: currentFilter) { newValue in
                                                applyImageAdjustments()
                                            }
                                        }
                                        .padding(.horizontal)
                                        
                                        // Format selection for export
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Export Format")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            Picker("Format", selection: $selectedExportFormat) {
                                                ForEach(ExportFormat.allCases) { format in
                                                    Text(format.rawValue).tag(format)
                                                }
                                            }
                                            .pickerStyle(SegmentedPickerStyle())
                                        }
                                        .padding(.horizontal)
                                        
                                        // Reset button
                                        Button(action: {
                                            resetImageEdits()
                                        }) {
                                            Label("Reset All", systemImage: "arrow.triangle.2.circlepath")
                                                .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(.bordered)
                                        .padding(.horizontal)
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        .onAppear {
                            // Calculate file size on appear
                            calculateFileSize(nsImage)
                        }
                    }
                }
            }
            
            Divider()
            
            // Actions with additional features
            HStack {
                Button(action: {
                    // Copy to clipboard (original or modified)
                    if let monitor = item.typeErasedClipboardMonitor as? ClipboardMonitor {
                        // If we have a modified image, copy that instead
                        if item.type == .image && modifiedImage != nil {
                            let modifiedItem = ClipboardItem(image: modifiedImage!)
                            monitor.copyToClipboard(modifiedItem)
                        } else {
                            monitor.copyToClipboard(item)
                        }
                    }
                }) {
                    Label("Copy to Clipboard", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
                
                if item.type == .image {
                    Button(action: {
                        // Save image to disk (original or modified)
                        saveImageToDisk()
                    }) {
                        Label("Save Image", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    
                    // OCR button if image
                    Button(action: {
                        performOCR()
                    }) {
                        if isPerformingOCR {
                            Label("Processing...", systemImage: "circle.dotted")
                        } else {
                            Label("Extract Text (OCR)", systemImage: "text.viewfinder")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isPerformingOCR)
                    
                    if modifiedImage != nil {
                        // Reset button
                        Button(action: {
                            resetImageEdits()
                        }) {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(.bordered)
                    }
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
        // Use modified image if available, otherwise use original
        guard let nsImage = modifiedImage ?? item.originalImage else { return }
        
        let savePanel = NSSavePanel()
        // Create array of allowed content types
        let contentTypes = [selectedExportFormat.uniformTypeIdentifier]
        savePanel.allowedContentTypes = contentTypes
        savePanel.nameFieldStringValue = "ClipWizard_Image_\(Int(Date().timeIntervalSince1970))"
        
        if savePanel.runModal() == .OK {
            if let url = savePanel.url {
                if let tiffData = nsImage.tiffRepresentation,
                   let bitmapImage = NSBitmapImageRep(data: tiffData) {
                    // Export in the selected format
                    var imageProperties: [NSBitmapImageRep.PropertyKey: Any] = [:]
                    let formatType: NSBitmapImageRep.FileType
                    
                    switch selectedExportFormat {
                    case .png: 
                        formatType = .png
                    case .jpeg: 
                        formatType = .jpeg
                        // Add JPEG compression quality (0.9 = 90% quality)
                        imageProperties[.compressionFactor] = 0.9
                    case .tiff: 
                        formatType = .tiff
                    case .bmp: 
                        formatType = .bmp
                    }
                    
                    if let imageData = bitmapImage.representation(using: formatType, properties: imageProperties) {
                        do {
                            try imageData.write(to: url)
                            logInfo("Image saved successfully to: \(url.path)")
                        } catch {
                            logError("Failed to save image: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    // Performs OCR on the image
    private func performOCR() {
        guard let nsImage = modifiedImage ?? item.originalImage else { return }
        isPerformingOCR = true
        
        // Convert NSImage to CGImage for Vision framework
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            isPerformingOCR = false
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.recognizedText = "OCR failed: \(error.localizedDescription)"
                    self.isPerformingOCR = false
                }
                return
            }
            
            // Process the recognized text
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            let result = recognizedStrings.joined(separator: " ")
            
            DispatchQueue.main.async {
                self.recognizedText = result.isEmpty ? "No text found in image" : result
                self.isPerformingOCR = false
            }
        }
        
        // Configure the request
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // Start the OCR process
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.recognizedText = "OCR processing failed"
                    self.isPerformingOCR = false
                }
            }
        }
    }
    
    // Calculate and format file size
    private func calculateFileSize(_ image: NSImage) {
        guard let tiffData = image.tiffRepresentation else {
            fileSize = "Unknown"
            return
        }
        
        let bytes = tiffData.count
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        fileSize = formatter.string(fromByteCount: Int64(bytes))
    }
    
    // Apply rotation to the image
    private func rotateImage(by degrees: Double) {
        rotationAngle += degrees
        // Keep angle between 0 and 360
        rotationAngle = rotationAngle.truncatingRemainder(dividingBy: 360)
        if rotationAngle < 0 {
            rotationAngle += 360
        }
        
        applyImageAdjustments()
    }
    
    // Reset all image edits
    private func resetImageEdits() {
        modifiedImage = nil
        rotationAngle = 0
        brightness = 0
        contrast = 1.0
        currentFilter = .none
        zoomLevel = 1.0
        dragOffset = .zero
        imagePosition = .zero
    }
    
    // Apply the current adjustments and filter to the image
    private func applyImageAdjustments() {
        guard let nsImage = item.originalImage else { return }
        
        // Convert NSImage to CIImage for processing
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        let ciImage = CIImage(cgImage: cgImage)
        
        // Create a CIContext for rendering
        let context = CIContext(options: nil)
        
        // Apply adjustments
        var processedImage = ciImage
        
        // Apply adjustments in sequence
        // Create a ColorControls filter for both brightness and contrast in one step
        if brightness != 0 || contrast != 1.0 {
        let adjustmentFilter = CIFilter.colorControls()
        adjustmentFilter.inputImage = processedImage
        adjustmentFilter.brightness = Float(brightness)
        adjustmentFilter.contrast = Float(contrast)
        adjustmentFilter.saturation = 1.0 // Keep saturation neutral
        
        if let outputImage = adjustmentFilter.outputImage {
            processedImage = outputImage
            }
        }
        
        // 3. Apply selected filter
        switch currentFilter {
        case .grayscale:
            let filter = CIFilter.photoEffectMono()
            filter.inputImage = processedImage
            if let outputImage = filter.outputImage {
                processedImage = outputImage
            }
            
        case .sepia:
            let filter = CIFilter.sepiaTone()
            filter.inputImage = processedImage
            filter.intensity = 0.8
            if let outputImage = filter.outputImage {
                processedImage = outputImage
            }
            
        case .invert:
            let filter = CIFilter.colorInvert()
            filter.inputImage = processedImage
            if let outputImage = filter.outputImage {
                processedImage = outputImage
            }
            
        case .blur:
            let filter = CIFilter.gaussianBlur()
            filter.inputImage = processedImage
            filter.radius = 3
            if let outputImage = filter.outputImage {
                processedImage = outputImage
            }
            
        case .sharpen:
            let filter = CIFilter.sharpenLuminance()
            filter.inputImage = processedImage
            filter.sharpness = 0.5
            if let outputImage = filter.outputImage {
                processedImage = outputImage
            }
            
        case .none:
            // No filter applied
            break
        }
        
        // Convert CIImage back to NSImage
        if let cgOutput = context.createCGImage(processedImage, from: processedImage.extent) {
            let newImage = NSImage(cgImage: cgOutput, size: nsImage.size)
            
            // Apply rotation if needed (this is done after filters because rotation is a geometric operation)
            if rotationAngle != 0 && rotationAngle != 360 {
                // Rotation is applied in the UI via SwiftUI's .rotationEffect to avoid pixelation
                // For saving and exporting, we would need to actually rotate the image data
            }
            
            modifiedImage = newImage
            
            // Recalculate file size for the modified image
            calculateFileSize(newImage)
        }
    }
}
