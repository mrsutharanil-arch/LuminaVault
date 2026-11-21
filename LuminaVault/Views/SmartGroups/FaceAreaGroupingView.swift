import SwiftUI
import UIKit

public struct FaceAreaGroupingView: View {
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
                        Image(systemName: "person.crop.rectangle.stack.fill")
                            .font(.system(size: 34))
                            .foregroundColor(.purple)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Face Area Recognition")
                                .font(.headline)
                            Text("Apple Vision isolates face coordinates, detects quality and clusters people.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                if !viewModel.faces.isEmpty {
                    // People Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button(action: { viewModel.selectedPersonFilter = nil }) {
                                Text("All People (\(viewModel.faces.count))")
                                    .font(.system(size: 13, weight: viewModel.selectedPersonFilter == nil ? .bold : .medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(Capsule().fill(viewModel.selectedPersonFilter == nil ? Color.purple : Color(UIColor.secondarySystemFill)))
                                    .foregroundColor(viewModel.selectedPersonFilter == nil ? .white : .primary)
                            }
                            
                            ForEach(viewModel.uniquePeopleNames, id: \.self) { name in
                                Button(action: { viewModel.selectedPersonFilter = name }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "person.fill")
                                            .font(.caption2)
                                        Text(name)
                                    }
                                    .font(.system(size: 13, weight: viewModel.selectedPersonFilter == name ? .bold : .medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(Capsule().fill(viewModel.selectedPersonFilter == name ? Color.purple : Color(UIColor.secondarySystemFill)))
                                    .foregroundColor(viewModel.selectedPersonFilter == name ? .white : .primary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                if viewModel.filteredFaces.isEmpty {
                    VStack(spacing: 12) {
                        Spacer().frame(height: 40)
                        Image(systemName: "person.crop.rectangle.stack")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("No Portraits Detected Yet")
                            .font(.headline)
                        Text("Tap 'Rescan' on the Smart Groups page to analyze your camera roll photos for people and faces using Apple Vision.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                } else {
                    // Grid of portraits
                    LazyVGrid(columns: columns, spacing: 3) {
                        ForEach(viewModel.filteredFaces) { item in
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
        .navigationTitle("Faces & People")
        .sheet(item: $selectedItem) { item in
            MediaDetailView(item: Binding(
                get: { item },
                set: { selectedItem = $0 }
            ))
        }
    }
}
