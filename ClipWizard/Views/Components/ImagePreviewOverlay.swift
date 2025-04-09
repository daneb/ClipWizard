import SwiftUI

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
