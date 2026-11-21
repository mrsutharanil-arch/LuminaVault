import SwiftUI

public struct GalleryView: View {
    @StateObject private var viewModel = GalleryViewModel()
    @ObservedObject private var scanner = PhotoLibraryScanner.shared
    @AppStorage("app_ui_theme") private var appUiTheme: String = "modern"
    
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
                        // Permission Notice Card
                        if scanner.permissionDenied {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.badge.exclamationmark")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)
                                Text("Photo Library Access Required")
                                    .font(.headline)
                                Text("LuminaVault needs access to your camera roll to display, organize, and group your photos & videos.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                Button(action: {
                                    scanner.openSystemSettings()
                                }) {
                                    Text("Open Settings")
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(18)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(14)
                            .padding(.horizontal)
                        }
                        
                        // Limited Access Notice
                        if scanner.isLimitedAccess {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Limited Photos Selected")
                                    .font(.caption.bold())
                                Spacer()
                                Button("Manage Photos") {
                                    scanner.presentLimitedPicker()
                                }
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.12))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                        
                        // Scanner Banner if actively scanning
                        if scanner.isScanning {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 4)
                                Text("Scanning iPhone Library (\(Int(scanner.scanProgress * 100))%)...")
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
                        
                        // Empty State
                        if viewModel.filteredItems.isEmpty && !scanner.isScanning {
                            VStack(spacing: 12) {
                                Spacer().frame(height: 50)
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 44))
                                    .foregroundColor(.secondary)
                                Text("No Items Found")
                                    .font(.headline)
                                Text("No photos or videos match your current filter.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            // 3-Column Grid with Real Thumbnails
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
                    HStack(spacing: 8) {
                        Button(action: {
                            Task {
                                await scanner.startFullLibraryScan()
                            }
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        
                        Button(action: {
                            appUiTheme = "metro"
                        }) {
                            HStack(spacing: 2) {
                                Image(systemName: "windows.logo")
                                    .font(.caption2)
                                Text("Metro")
                                    .font(.caption2.bold())
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.15))
                            .cornerRadius(4)
                        }
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
