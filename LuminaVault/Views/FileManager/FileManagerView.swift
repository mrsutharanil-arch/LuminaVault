import SwiftUI
import UIKit

public struct FileManagerView: View {
    @StateObject private var viewModel = FileManagerViewModel()
    @State private var showExifItem: MediaItem? = nil
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Phone Storage Meter Card
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "iphone.gen3")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("iPhone 14 Storage")
                                        .font(.headline)
                                    Text("\(viewModel.fileManagerService.storageBreakdown.formattedUsed) of \(viewModel.fileManagerService.storageBreakdown.formattedTotal) Used")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("\(viewModel.fileManagerService.storageBreakdown.formattedFree) Free")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundColor(.green)
                                    .cornerRadius(8)
                            }
                            
                            // Multi-color segmented storage bar
                            GeometryReader { geo in
                                HStack(spacing: 2) {
                                    ForEach(viewModel.fileManagerService.storageBreakdown.categories) { cat in
                                        let ratio = Double(cat.bytes) / Double(max(1, viewModel.fileManagerService.storageBreakdown.totalPhoneStorageBytes))
                                        let width = max(4, CGFloat(ratio) * geo.size.width)
                                        Rectangle()
                                            .fill(cat.color)
                                            .frame(width: width)
                                    }
                                    
                                    // Other OS / Apps
                                    let otherRatio = 0.35
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.4))
                                        .frame(width: CGFloat(otherRatio) * geo.size.width)
                                }
                                .cornerRadius(6)
                            }
                            .frame(height: 12)
                            
                            // Legend
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(viewModel.fileManagerService.storageBreakdown.categories) { cat in
                                        HStack(spacing: 5) {
                                            Circle()
                                                .fill(cat.color)
                                                .frame(width: 8, height: 8)
                                            Text("\(cat.title): \(cat.formattedSize)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Optimization & Cleaner Actions
                    VStack(spacing: 12) {
                        // 1. Duplicate Cleaner
                        if !viewModel.fileManagerService.duplicateClusters.isEmpty {
                            GlassCard {
                                VStack(spacing: 12) {
                                    HStack(spacing: 14) {
                                        Image(systemName: "square.stack.3d.down.right.fill")
                                            .font(.title2)
                                            .foregroundColor(.orange)
                                        
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text("Duplicate Photos Detected")
                                                .font(.subheadline.bold())
                                            Text("\(viewModel.fileManagerService.duplicateClusters.count) clusters found • Recover up to \(viewModel.fileManagerService.duplicateClusters.reduce(0) { $0 + $1.recoverableBytes } / (1024 * 1024)) MB")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                    
                                    Button(action: {
                                        Task {
                                            await viewModel.cleanAllDuplicates()
                                        }
                                    }) {
                                        HStack {
                                            if viewModel.isCleaning {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            } else {
                                                Image(systemName: "sparkles")
                                            }
                                            Text(viewModel.isCleaning ? "Cleaning Duplicates..." : "Clean All Duplicates")
                                        }
                                        .font(.caption.bold())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 9)
                                        .background(Color.orange)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Large Files Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Large Files & 4K Clips (>8 MB)")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            ForEach(viewModel.fileManagerService.largeMediaItems.prefix(5)) { item in
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(item.mediaType == .video ? Color.purple.opacity(0.2) : Color.blue.opacity(0.2))
                                            .frame(width: 48, height: 48)
                                        Image(systemName: item.mediaType.iconName)
                                            .foregroundColor(item.mediaType == .video ? .purple : .blue)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.filename)
                                            .font(.subheadline.bold())
                                            .lineLimit(1)
                                        Text("\(item.formattedDimensions) • \(item.formattedDate)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(item.formattedFileSize)
                                            .font(.caption.bold())
                                            .foregroundColor(.red)
                                        
                                        Button(action: {
                                            showExifItem = item
                                        }) {
                                            Image(systemName: "info.circle")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer().frame(height: 80)
                }
                .padding(.vertical)
            }
            .navigationTitle("File Manager")
            .sheet(item: $showExifItem) { item in
                ExifDetailSheet(item: item)
            }
            .onAppear {
                viewModel.refreshStorage()
            }
        }
    }
}
