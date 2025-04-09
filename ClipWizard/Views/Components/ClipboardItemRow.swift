import SwiftUI

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
