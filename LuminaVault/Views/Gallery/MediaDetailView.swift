import SwiftUI

public struct MediaDetailView: View {
    @Binding public var item: MediaItem?
    @State private var showExifDetails: Bool = false
    @State private var showPrivateVaultAlert: Bool = false
    @State private var copiedTextAlert: Bool = false
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
                            Rectangle()
                                .fill(Color.black)
                            
                            VStack {
                                Spacer()
                                Image(systemName: media.mediaType.iconName)
                                    .font(.system(size: 72))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text(media.filename)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.top, 8)
                                
                                if let duration = media.formattedDuration {
                                    Text("Video • \(duration)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            
                            // OCR text banner if available
                            if let text = media.detectedText {
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
                        HStack(spacing: 24) {
                            // Favorite Button
                            Button(action: {
                                if var current = item {
                                    current.isFavorite.toggle()
                                    item = current
                                    if let idx = PhotoLibraryScanner.shared.allMediaItems.firstIndex(where: { $0.id == current.id }) {
                                        PhotoLibraryScanner.shared.allMediaItems[idx].isFavorite = current.isFavorite
                                    }
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: media.isFavorite ? "heart.fill" : "heart")
                                        .foregroundColor(media.isFavorite ? .red : .white)
                                    Text("Favorite")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Backup to Google Photos
                            Button(action: {
                                GooglePhotosService.shared.queueSingleItem(item: media)
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.2.circlepath.icloud")
                                        .foregroundColor(.blue)
                                    Text("Cloud Backup")
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
                                    Text("Info & EXIF")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.secondarySystemBackground).opacity(0.2))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        item = nil
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showExifDetails) {
                if let media = item {
                    ExifDetailSheet(item: media)
                }
            }
            .alert("Lock Photo in Private Vault?", isPresented: $showPrivateVaultAlert) {
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
                Text("This file will be encrypted using 256-bit AES-GCM and stored in a secure sandbox. It requires Face ID to unlock.")
            }
            .alert("OCR Text Copied", isPresented: $copiedTextAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }
}
