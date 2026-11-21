import SwiftUI
import UIKit

public struct ShortPhotosView: View {
    @ObservedObject public var viewModel: SmartGroupingViewModel
    @State private var selectedItem: MediaItem? = nil
    
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
                // Header Card
                GlassCard {
                    HStack(spacing: 16) {
                        Image(systemName: "livephoto.play")
                            .font(.system(size: 34))
                            .foregroundColor(.pink)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Short Photos & Live Clips")
                                .font(.headline)
                            Text("Live Photos, burst sequences, and micro-clips under 15 seconds.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                if viewModel.shortPhotos.isEmpty {
                    VStack(spacing: 12) {
                        Spacer().frame(height: 40)
                        Image(systemName: "livephoto.slash")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("No Short Photos or Live Clips")
                            .font(.headline)
                        Text("Live Photos, bursts, and video clips under 15 seconds will appear here.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                } else {
                    // Grid
                    LazyVGrid(columns: columns, spacing: 3) {
                        ForEach(viewModel.shortPhotos) { item in
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
        .navigationTitle("Short Photos & Live")
        .sheet(item: $selectedItem) { item in
            MediaDetailView(item: Binding(
                get: { item },
                set: { selectedItem = $0 }
            ))
        }
    }
}
