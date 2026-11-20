import SwiftUI

public struct DocumentScannerView: View {
    @ObservedObject public var viewModel: SmartGroupingViewModel
    @State private var selectedItem: MediaItem? = nil
    
    public init(viewModel: SmartGroupingViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header card
                GlassCard {
                    HStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Apple Vision OCR Scanner")
                                .font(.headline)
                            Text("Automatically detects printed text, receipts, forms, and business cards.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Search bar for OCR content
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search text inside scanned documents...", text: $viewModel.documentSearchText)
                        .font(.subheadline)
                }
                .padding(10)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Document List
                VStack(spacing: 12) {
                    ForEach(viewModel.filteredDocuments) { doc in
                        Button(action: {
                            selectedItem = doc
                        }) {
                            HStack(alignment: .top, spacing: 14) {
                                // Thumbnail
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(LinearGradient(colors: [.yellow.opacity(0.3), .orange.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 70, height: 90)
                                    Image(systemName: "doc.text.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(doc.filename)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    if let text = doc.detectedText {
                                        Text(text)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(3)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    HStack {
                                        Text(doc.formattedDate)
                                        Spacer()
                                        Text(doc.formattedFileSize)
                                    }
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.04), radius: 4)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Documents & Receipts")
        .sheet(item: $selectedItem) { item in
            MediaDetailView(item: Binding(
                get: { item },
                set: { selectedItem = $0 }
            ))
        }
    }
}
