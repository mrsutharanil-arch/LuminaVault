import SwiftUI

public struct GalleryView: View {
    @StateObject private var viewModel = GalleryViewModel()
    @ObservedObject private var scanner = PhotoLibraryScanner.shared
    
    private let columns = [
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3)
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 8) {
                        // Scanner Banner if actively scanning
                        if scanner.isScanning {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 4)
                                Text("Scanning iPhone 14 Library (\(Int(scanner.scanProgress * 100))%)...")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(scanner.totalScannedCount) files")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.85))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                        
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search photos, text, or location...", text: $viewModel.searchText)
                                .font(.subheadline)
                            if !viewModel.searchText.isEmpty {
                                Button(action: { viewModel.searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        
                        // Filter Pills
                        FilterSegmentBar(selectedSegment: $viewModel.selectedFilter)
                        
                        // Summary info
                        HStack {
                            Text("\(viewModel.filteredItems.count) Items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Menu {
                                ForEach(SortOrderOption.allCases) { opt in
                                    Button(action: { viewModel.sortOption = opt }) {
                                        HStack {
                                            Text(opt.rawValue)
                                            if viewModel.sortOption == opt {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(viewModel.sortOption.rawValue)
                                    Image(systemName: "arrow.up.arrow.down")
                                }
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        // 3-Column Grid
                        LazyVGrid(columns: columns, spacing: 3) {
                            ForEach(viewModel.filteredItems) { item in
                                MediaThumbnailView(
                                    item: item,
                                    isSelected: viewModel.selectedItemIds.contains(item.id),
                                    showSelectionCheckmark: viewModel.isSelectMode
                                )
                                .onTapGesture {
                                    if viewModel.isSelectMode {
                                        viewModel.toggleSelection(for: item)
                                    } else {
                                        viewModel.selectedMediaForDetail = item
                                    }
                                }
                            }
                        }
                        
                        // Space for floating tab bar / selection bar
                        Spacer()
                            .frame(height: 100)
                    }
                }
                
                // Multi-select Action Bar
                if viewModel.isSelectMode {
                    VStack {
                        Spacer()
                        HStack(spacing: 16) {
                            Button(action: {
                                Task {
                                    await viewModel.moveSelectedToVault()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "lock.shield.fill")
                                    Text("Lock Vault")
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(20)
                            }
                            
                            Button(action: {
                                viewModel.backupSelectedToGooglePhotos()
                            }) {
                                HStack {
                                    Image(systemName: "icloud.and.arrow.up.fill")
                                    Text("Cloud Backup")
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                            }
                            
                            Spacer()
                            
                            Text("\(viewModel.selectedItemIds.count) selected")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.9))
                        .cornerRadius(24)
                        .padding(.horizontal)
                        .padding(.bottom, 60)
                    }
                }
            }
            .navigationTitle("Lumina Photos")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            await scanner.startFullLibraryScan()
                        }
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(viewModel.isSelectMode ? "Done" : "Select") {
                        withAnimation {
                            if viewModel.isSelectMode {
                                viewModel.clearSelection()
                            } else {
                                viewModel.isSelectMode = true
                            }
                        }
                    }
                    .font(.subheadline.bold())
                }
            }
            .sheet(item: $viewModel.selectedMediaForDetail) { item in
                MediaDetailView(item: Binding(
                    get: { item },
                    set: { viewModel.selectedMediaForDetail = $0 }
                ))
            }
        }
    }
}
