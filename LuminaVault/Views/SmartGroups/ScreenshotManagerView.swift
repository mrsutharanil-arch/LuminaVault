import SwiftUI

public struct ScreenshotManagerView: View {
    @ObservedObject public var viewModel: SmartGroupingViewModel
    @State private var selectedItem: MediaItem? = nil
    @State private var showCleanAlert: Bool = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3)
    ]
    
    public init(viewModel: SmartGroupingViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Card with 1-Tap Cleanup
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 16) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 34))
                                .foregroundColor(.cyan)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Screenshot Cleaner")
                                    .font(.headline)
                                Text("\(viewModel.screenshots.count) captures taking phone storage")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        
                        if !viewModel.screenshots.isEmpty {
                            Button(action: {
                                showCleanAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("Clean Screenshots > 7 Days")
                                }
                                .font(.caption.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Color.cyan)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                if viewModel.screenshots.isEmpty {
                    VStack(spacing: 12) {
                        Spacer().frame(height: 40)
                        Image(systemName: "camera.metering.none")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("No Screenshots Found")
                            .font(.headline)
                        Text("Screenshots and screen recordings taken on this iPhone will be grouped here.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                } else {
                    // Grid of Screenshots
                    LazyVGrid(columns: columns, spacing: 3) {
                        ForEach(viewModel.screenshots) { item in
                            MediaThumbnailView(item: item)
                                .onTapGesture {
                                    selectedItem = item
                                }
                        }
                    }
                }
                
                Spacer().frame(height: 50)
            }
            .padding(.vertical)
        }
        .navigationTitle("Screenshots & Clips")
        .alert("Clean Old Screenshots?", isPresented: $showCleanAlert) {
            Button("Delete Old", role: .destructive) {
                viewModel.deleteOldScreenshots()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Screenshots older than 7 days will be deleted to free up iPhone storage.")
        }
        .sheet(item: $selectedItem) { item in
            MediaDetailView(item: Binding(
                get: { item },
                set: { selectedItem = $0 }
            ))
        }
    }
}
