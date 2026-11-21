import SwiftUI
import UIKit

public struct SmartGroupsHubView: View {
    @StateObject private var viewModel = SmartGroupingViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Deep Vision Scan Trigger Banner
                    HStack(spacing: 14) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.yellow)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Apple Neural Engine Grouping")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Text("Scans all media on phone for documents, faces, areas & short photos.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.85))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            Task {
                                await viewModel.runDeepVisionScan()
                            }
                        }) {
                            Text(viewModel.isAnalyzingVision ? "Scanning..." : "Rescan")
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(14)
                        }
                    }
                    .padding()
                    .background(LinearGradient(colors: [Color.indigo, Color.purple], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // 6 Smart Group Cards
                    VStack(spacing: 14) {
                        // 1. Videos & 4K Clips
                        NavigationLink(destination: VideosGroupView(viewModel: viewModel)) {
                            SmartGroupCardView(
                                groupType: .videos,
                                count: viewModel.videos.count,
                                coverGradient: [Color.blue, Color.purple]
                            )
                        }
                        
                        // 2. Documents
                        NavigationLink(destination: DocumentScannerView(viewModel: viewModel)) {
                            SmartGroupCardView(
                                groupType: .documents,
                                count: viewModel.documents.count,
                                coverGradient: [Color.orange, Color.red]
                            )
                        }
                        
                        // 3. Face Areas & People
                        NavigationLink(destination: FaceAreaGroupingView(viewModel: viewModel)) {
                            SmartGroupCardView(
                                groupType: .faces,
                                count: viewModel.faces.count,
                                coverGradient: [Color.purple, Color.indigo]
                            )
                        }
                        
                        // 4. Area & Locations
                        NavigationLink(destination: LocationGroupingView(viewModel: viewModel)) {
                            SmartGroupCardView(
                                groupType: .areas,
                                count: viewModel.areaClusters.count,
                                coverGradient: [Color.teal, Color.blue]
                            )
                        }
                        
                        // 5. Screenshots & Clips
                        NavigationLink(destination: ScreenshotManagerView(viewModel: viewModel)) {
                            SmartGroupCardView(
                                groupType: .screenshots,
                                count: viewModel.screenshots.count,
                                coverGradient: [Color.cyan, Color.blue]
                            )
                        }
                        
                        // 6. Short Photos & Live
                        NavigationLink(destination: ShortPhotosView(viewModel: viewModel)) {
                            SmartGroupCardView(
                                groupType: .shortPhotos,
                                count: viewModel.shortPhotos.count,
                                coverGradient: [Color.pink, Color.purple]
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer().frame(height: 80)
                }
                .padding(.vertical)
            }
            .navigationTitle("Smart Groups")
            .onAppear {
                viewModel.refreshGroups()
            }
        }
    }
}

public struct VideosGroupView: View {
    @ObservedObject public var viewModel: SmartGroupingViewModel
    @State private var selectedItem: MediaItem? = nil
    
    private let columns = [
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3)
    ]
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GlassCard {
                    HStack(spacing: 16) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 34))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("iPhone Videos Collection")
                                .font(.headline)
                            Text("\(viewModel.videos.count) videos • Total: \(ByteCountFormatter.string(fromByteCount: viewModel.videos.reduce(0) { $0 + $1.fileSize }, countStyle: .file))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal)
                
                if viewModel.videos.isEmpty {
                    VStack(spacing: 12) {
                        Spacer().frame(height: 50)
                        Image(systemName: "video.slash")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("No Videos Found")
                            .font(.headline)
                        Text("No video recordings found in your camera roll.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(viewModel.videos) { video in
                            MediaThumbnailView(item: video)
                                .onTapGesture {
                                    selectedItem = video
                                }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                
                Spacer().frame(height: 50)
            }
            .padding(.vertical)
        }
        .navigationTitle("Videos & 4K Clips")
        .sheet(item: $selectedItem) { item in
            MediaDetailView(item: Binding(
                get: { item },
                set: { selectedItem = $0 }
            ))
        }
    }
}

public struct SmartGroupCardView: View {
    public let groupType: SmartGroupType
    public let count: Int
    public let coverGradient: [Color]
    
    public var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: coverGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 58, height: 58)
                Image(systemName: groupType.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(groupType.rawValue)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                Text(groupType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("\(count)")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}
