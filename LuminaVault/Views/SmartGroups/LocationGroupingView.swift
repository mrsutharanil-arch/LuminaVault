import SwiftUI

public struct LocationGroupingView: View {
    @ObservedObject public var viewModel: SmartGroupingViewModel
    @State private var selectedCollection: GroupedCollection? = nil
    @State private var selectedItem: MediaItem? = nil
    
    public init(viewModel: SmartGroupingViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Card
                GlassCard {
                    HStack(spacing: 16) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 34))
                            .foregroundColor(.teal)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Area & Geolocation Clusters")
                                .font(.headline)
                            Text("Reverse geocoded from GPS EXIF coordinates into cities and regions.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                if viewModel.areaClusters.isEmpty {
                    VStack(spacing: 12) {
                        Spacer().frame(height: 40)
                        Image(systemName: "location.slash")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("No Location Data Found")
                            .font(.headline)
                        Text("Photos taken with Camera GPS location enabled will be clustered into cities and regions here.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                } else {
                    // Location Cards
                    VStack(spacing: 12) {
                        ForEach(viewModel.areaClusters) { cluster in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.teal)
                                    Text(cluster.title)
                                        .font(.system(size: 16, weight: .bold))
                                    Spacer()
                                    Text(cluster.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Horizontal preview strip
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(cluster.items) { item in
                                            MediaThumbnailView(item: item)
                                                .frame(width: 80, height: 80)
                                                .onTapGesture {
                                                    selectedItem = item
                                                }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(14)
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer().frame(height: 50)
            }
            .padding(.vertical)
        }
        .navigationTitle("Areas & Locations")
        .sheet(item: $selectedItem) { item in
            MediaDetailView(item: Binding(
                get: { item },
                set: { selectedItem = $0 }
            ))
        }
    }
}
