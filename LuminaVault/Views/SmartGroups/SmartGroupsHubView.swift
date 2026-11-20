import SwiftUI

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
                    
                    // 5 Smart Group Cards
                    VStack(spacing: 14) {
                        // 1. Documents
                        NavigationLink(destination: DocumentScannerView(viewModel: viewModel)) {
                            SmartGroupCardView(
                                groupType: .documents,
                                count: viewModel.documents.count,
                                coverGradient: [Color.orange, Color.red]
                            )
                        }
                        
                        // 2. Face Areas & People
                        NavigationLink(destination: FaceAreaGroupingView(viewModel: viewModel)) {
                            SmartGroupCardView(
                                groupType: .faces,
                                count: viewModel.faces.count,
                                coverGradient: [Color.purple, Color.indigo]
                            )
                        }
                        
                        // 3. Area & Locations
                        NavigationLink(destination: LocationGroupingView(viewModel: viewModel)) {
                            SmartGroupCardView(
                                groupType: .areas,
                                count: viewModel.areaClusters.count,
                                coverGradient: [Color.teal, Color.blue]
                            )
                        }
                        
                        // 4. Screenshots & Clips
                        NavigationLink(destination: ScreenshotManagerView(viewModel: viewModel)) {
                            SmartGroupCardView(
                                groupType: .screenshots,
                                count: viewModel.screenshots.count,
                                coverGradient: [Color.cyan, Color.blue]
                            )
                        }
                        
                        // 5. Short Photos & Live
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
