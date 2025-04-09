import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers

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
                        textContentView
                    } else if item.type == .image, let nsImage = item.originalImage {
                        imageContentView(nsImage: nsImage)
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
    
    // MARK: - Text Content View
    
    private var textContentView: some View {
        Group {
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
        }
    }
    
    // MARK: - Image Content View
    
    @ViewBuilder
    private func imageContentView(nsImage: NSImage) -> some View {
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
                imagePreviewView(nsImage: nsImage)
            } else {
                imageEditView(nsImage: nsImage)
            }
        }
        .onAppear {
            // Calculate file size on appear
            fileSize = ImageProcessor.calculateFileSize(nsImage)
        }
    }
    
    // MARK: - Image Preview View
    
    @ViewBuilder
    private func imagePreviewView(nsImage: NSImage) -> some View {
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
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("OCR Text:")
                                .fontWeight(.semibold)
                                
                            Spacer()
                            
                            Button(action: {
                                copyOCRTextToClipboard()
                            }) {
                                Label("Copy OCR Text", systemImage: "doc.on.doc")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .help("Copy the full OCR text to clipboard")
                        }
                        
                        ScrollView {
                            Text(recognizedText)
                                .foregroundColor(.primary)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                                .lineLimit(nil)
                                .padding(8)
                                .background(Color(.textBackgroundColor))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .frame(maxHeight: 120)
                    }
                    .padding(.top, 4)
                }
            }
            .font(.caption)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Image Edit View
    
    @ViewBuilder
    private func imageEditView(nsImage: NSImage) -> some View {
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
    
    // MARK: - Helper Methods
    
    private func copyOCRTextToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(recognizedText, forType: .string)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    private func saveImageToDisk() {
        // Use modified image if available, otherwise use original
        guard let nsImage = modifiedImage ?? item.originalImage else { return }
        ImageProcessor.saveImageToDisk(image: nsImage, format: selectedExportFormat)
    }
    
    private func performOCR() {
        guard let nsImage = modifiedImage ?? item.originalImage else { return }
        isPerformingOCR = true
        
        ImageProcessor.performOCR(on: nsImage) { result in
            // Limit OCR text to reasonable size if needed (approximately 500 lines)
            let lines = result.components(separatedBy: .newlines)
            if lines.count > 500 {
                let truncatedLines = Array(lines.prefix(500))
                self.recognizedText = truncatedLines.joined(separator: "\n") + "\n\n[... Text truncated. Use 'Copy OCR Text' to get full content ...]" 
            } else {
                self.recognizedText = result
            }
            self.isPerformingOCR = false
        }
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
        
        modifiedImage = ImageProcessor.applyAdjustments(
            to: nsImage,
            brightness: brightness,
            contrast: contrast,
            filter: currentFilter,
            rotationAngle: rotationAngle
        )
        
        // Recalculate file size if we have a modified image
        if let modifiedImage = modifiedImage {
            fileSize = ImageProcessor.calculateFileSize(modifiedImage)
        }
    }
}
