import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    var isSelected: Bool = false
    
    @State private var loadedImage: NSImage? = nil
    
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
                    Text(getTextContent())
                        .lineLimit(2)
                        .font(.callout)
                        .foregroundColor(isSelected ? .primary : .secondary)
                } else if item.type == .image {
                    Group {
                        if let nsImage = loadedImage ?? item.originalImage {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 80)
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                        } else {
                            // Placeholder while image is loading
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 80)
                                .cornerRadius(4)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                )
                                .onAppear {
                                    loadImage()
                                }
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        }
        .contentShape(Rectangle())
        .cornerRadius(6)
        .onAppear {
            if item.type == .image && loadedImage == nil && item.originalImage == nil {
                loadImage()
            }
        }
    }
    
    private func loadImage() {
        // Use the async version for better performance and to avoid UI blocking
        item.reloadImage { loadedImage in
            // We need to use a capture list here since self is a struct (not a class)
            // and 'weak' can only be applied to class types
            self.loadedImage = loadedImage
        }
    }
    
    private func getTextContent() -> String {
        // If text is compressed, decompress it
        if let decompressedText = item.decompressText() {
            return item.sanitizedText ?? decompressedText
        }
        return item.sanitizedText ?? item.originalText ?? ""
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
