import SwiftUI
import Photos
import AVKit

public struct MediaDetailView: View {
    @Binding public var item: MediaItem?
    @State private var showExifDetails: Bool = false
    @State private var showPrivateVaultAlert: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var copiedTextAlert: Bool = false
    @State private var fullImage: UIImage? = nil
    @State private var avPlayer: AVPlayer? = nil
    @State private var isLoadingAsset: Bool = true
    @State private var scale: CGFloat = 1.0
    @State private var showShareSheet: Bool = false
    @State private var shareItems: [Any] = []
    
    @Environment(\.dismiss) private var dismiss
    
    public init(item: Binding<MediaItem?>) {
        self._item = item
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let media = item {
                    VStack(spacing: 0) {
                        // Media Display Area
                        ZStack {
                            if media.mediaType == .video {
                                // Real Video Player
                                if let player = avPlayer {
                                    VideoPlayer(player: player)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .onAppear {
                                            player.play()
                                        }
                                        .onDisappear {
                                            player.pause()
                                        }
                                } else {
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .tint(.white)
                                        Text("Loading Video...")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                            } else {
                                // Real Photo Viewer with Zoom
                                if let image = fullImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .scaleEffect(scale)
                                        .gesture(
                                            MagnificationGesture()
                                                .onChanged { val in
                                                    scale = max(1.0, min(val, 4.0))
                                                }
                                                .onEnded { _ in
                                                    if scale < 1.05 {
                                                        scale = 1.0
                                                    }
                                                }
                                        )
                                        .onTapGesture(count: 2) {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                scale = scale > 1.2 ? 1.0 : 2.5
                                            }
                                        }
                                } else {
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .tint(.white)
                                        Text("Loading High-Res Photo...")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                            }
                            
                            // OCR text banner if available
                            if let text = media.detectedText, !text.isEmpty {
                                VStack {
                                    Spacer()
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Image(systemName: "doc.text.viewfinder")
                                                    .foregroundColor(.orange)
                                                Text("Recognized Document Text")
                                                    .font(.caption.bold())
                                                    .foregroundColor(.white)
                                            }
                                            Text(text.prefix(120) + (text.count > 120 ? "..." : ""))
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.85))
                                        }
                                        Spacer()
                                        Button(action: {
                                            UIPasteboard.general.string = text
                                            copiedTextAlert = true
                                        }) {
                                            Image(systemName: "doc.on.doc")
                                                .foregroundColor(.orange)
                                                .padding(8)
                                                .background(Color.white.opacity(0.1))
                                                .clipShape(Circle())
                                        }
                                    }
                                    .padding()
                                    .background(Color.black.opacity(0.8))
                                    .cornerRadius(12)
                                    .padding()
                                }
                            }
                        }
                        .frame(maxHeight: .infinity)
                        
                        // Bottom Action Bar
                        HStack(spacing: 20) {
                            // Favorite Button
                            Button(action: {
                                toggleFavorite(for: media)
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: media.isFavorite ? "heart.fill" : "heart")
                                        .foregroundColor(media.isFavorite ? .red : .white)
                                    Text("Favorite")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Share Button
                            Button(action: {
                                prepareShare(for: media)
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.white)
                                    Text("Share")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Move to Private Vault
                            Button(action: {
                                showPrivateVaultAlert = true
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "lock.shield.fill")
                                        .foregroundColor(.yellow)
                                    Text("Lock in Vault")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // EXIF Info Inspector
                            Button(action: {
                                showExifDetails.toggle()
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.white)
                                    Text("Info")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Delete Button
                            Button(action: {
                                showDeleteAlert = true
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                    Text("Delete")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.secondarySystemBackground).opacity(0.25))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        avPlayer?.pause()
                        item = nil
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Done")
                        }
                        .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    if let media = item {
                        VStack(spacing: 1) {
                            Text(media.filename)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(media.formattedDate)
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .onAppear {
                loadMediaContent()
            }
            .onDisappear {
                avPlayer?.pause()
                avPlayer = nil
            }
            .sheet(isPresented: $showExifDetails) {
                if let media = item {
                    ExifDetailSheet(item: media)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ActivityViewWrapper(activityItems: shareItems)
            }
            .alert("Lock in Private Vault?", isPresented: $showPrivateVaultAlert) {
                Button("Move & Encrypt", role: .destructive) {
                    if let media = item {
                        Task {
                            _ = await PrivateVaultService.shared.moveToPrivateVault(item: media, deleteOriginal: true)
                            item = nil
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This file will be encrypted using 256-bit AES-GCM and stored securely inside your Private Vault.")
            }
            .alert("Delete from Camera Roll?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let media = item {
                        deleteFromCameraRoll(media: media)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This item will be moved to Recently Deleted in your iPhone Photos library.")
            }
            .alert("OCR Text Copied", isPresented: $copiedTextAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }
    
    private func loadMediaContent() {
        guard let media = item, let localId = media.phAssetLocalId else { return }
        
        if media.mediaType == .video {
            PhotoAssetLoader.shared.loadAVPlayerItem(for: localId) { playerItem in
                if let pItem = playerItem {
                    self.avPlayer = AVPlayer(playerItem: pItem)
                    self.isLoadingAsset = false
                }
            }
        } else {
            PhotoAssetLoader.shared.loadFullImage(for: localId) { img in
                if let image = img {
                    self.fullImage = image
                    self.isLoadingAsset = false
                }
            }
        }
    }
    
    private func toggleFavorite(for media: MediaItem) {
        guard let localId = media.phAssetLocalId else { return }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localId], options: nil)
        guard let asset = assets.firstObject else { return }
        
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest(for: asset)
            request.isFavorite = !asset.isFavorite
        }) { success, _ in
            if success {
                DispatchQueue.main.async {
                    if var current = item {
                        current.isFavorite.toggle()
                        item = current
                    }
                    if let idx = PhotoLibraryScanner.shared.allMediaItems.firstIndex(where: { $0.id == media.id }) {
                        PhotoLibraryScanner.shared.allMediaItems[idx].isFavorite.toggle()
                        PhotoLibraryScanner.shared.updateCategorizedCaches()
                    }
                }
            }
        }
    }
    
    private func deleteFromCameraRoll(media: MediaItem) {
        guard let localId = media.phAssetLocalId else { return }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localId], options: nil)
        guard let asset = assets.firstObject else { return }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([asset] as NSArray)
        }) { success, _ in
            if success {
                DispatchQueue.main.async {
                    PhotoLibraryScanner.shared.allMediaItems.removeAll { $0.id == media.id }
                    PhotoLibraryScanner.shared.updateCategorizedCaches()
                    item = nil
                }
            }
        }
    }
    
    private func prepareShare(for media: MediaItem) {
        if let img = fullImage {
            self.shareItems = [img]
            self.showShareSheet = true
        } else if let localId = media.phAssetLocalId {
            PhotoAssetLoader.shared.loadThumbnail(for: localId, targetSize: CGSize(width: 800, height: 800)) { img in
                if let image = img {
                    self.shareItems = [image]
                    self.showShareSheet = true
                }
            }
        }
    }
}

// Helper struct for UIKit UIActivityViewController in SwiftUI
public struct ActivityViewWrapper: UIViewControllerRepresentable {
    public let activityItems: [Any]
    public let applicationActivities: [UIActivity]? = nil
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
