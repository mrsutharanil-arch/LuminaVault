import SwiftUI
import UIKit
import Photos

public struct MediaThumbnailView: View {
    public let item: MediaItem
    public var isSelected: Bool = false
    public var showSelectionCheckmark: Bool = false
    
    @State private var thumbnailImage: UIImage? = nil
    @State private var requestId: PHImageRequestID? = nil
    
    public init(item: MediaItem, isSelected: Bool = false, showSelectionCheckmark: Bool = false) {
        self.item = item
        self.isSelected = isSelected
        self.showSelectionCheckmark = showSelectionCheckmark
    }
    
    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Real Image Thumbnail / Smooth placeholder
            GeometryReader { geo in
                ZStack {
                    if let image = thumbnailImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color(UIColor.secondarySystemBackground))
                            .overlay(
                                Image(systemName: item.mediaType.iconName)
                                    .font(.system(size: 24))
                                    .foregroundColor(.secondary.opacity(0.6))
                            )
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .cornerRadius(8)
            .clipped()
            
            // Top Badges
            VStack {
                HStack(spacing: 4) {
                    if item.isDocument {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.text.fill")
                            Text("OCR")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    } else if item.isFaceGroup {
                        HStack(spacing: 3) {
                            Image(systemName: "person.crop.square.fill")
                            Text("\(item.detectedFaces.count)")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    } else if item.isScreenshot {
                        Text("SHOT")
                            .font(.system(size: 8, weight: .heavy))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.cyan.opacity(0.9))
                            .foregroundColor(.black)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    if item.backupStatus != .notUploaded {
                        Image(systemName: item.backupStatus.iconName)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(item.backupStatus.tintColor)
                            .padding(3)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding(5)
                
                Spacer()
                
                // Bottom Bar (Duration for video / Live badge / Favorite)
                HStack(spacing: 4) {
                    if item.mediaType == .video {
                        HStack(spacing: 3) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 8))
                            if let duration = item.formattedDuration {
                                Text(duration)
                                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            }
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.75))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    } else if item.mediaType == .livePhoto {
                        HStack(spacing: 2) {
                            Image(systemName: "livephoto")
                            Text("LIVE")
                        }
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.65))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    if item.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                            .shadow(color: .black.opacity(0.6), radius: 2)
                    }
                }
                .padding(5)
            }
            
            // Selection Checkmark Overlay
            if showSelectionCheckmark {
                ZStack {
                    Color.black.opacity(isSelected ? 0.35 : 0.05)
                    
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(isSelected ? .blue : .white)
                                .shadow(color: .black.opacity(0.6), radius: 3)
                                .padding(6)
                        }
                        Spacer()
                    }
                }
                .cornerRadius(8)
            }
        }
        .contentShape(Rectangle())
        .onAppear {
            loadThumbnail()
        }
        .onDisappear {
            if let req = requestId {
                PhotoAssetLoader.shared.cancelRequest(req)
            }
        }
    }
    
    private func loadThumbnail() {
        guard let localId = item.phAssetLocalId else { return }
        
        // Fast-path memory cache hit
        if let cached = PhotoAssetLoader.shared.cachedThumbnail(for: localId) {
            self.thumbnailImage = cached
            return
        }
        
        // Async load
        self.requestId = PhotoAssetLoader.shared.loadThumbnail(for: localId, targetSize: CGSize(width: 250, height: 250)) { image in
            if let img = image {
                withAnimation(.easeOut(duration: 0.15)) {
                    self.thumbnailImage = img
                }
            }
        }
    }
}
