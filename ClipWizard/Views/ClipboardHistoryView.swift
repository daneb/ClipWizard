import SwiftUI

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
                        .accessibility(identifier: "SearchField")
                    
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
                    emptyStateView
                } else {
                    clipboardItemsListView
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
            bottomToolbarView
            
            // Floating image preview overlay
            ImagePreviewOverlay(hoveredItem: hoveredItem, showingHoverPreview: showingHoverPreview)
                .zIndex(100)
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
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
    }
    
    // MARK: - Clipboard Items List View
    
    private var clipboardItemsListView: some View {
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
    
    // MARK: - Bottom Toolbar View
    
    private var bottomToolbarView: some View {
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
    }
}
