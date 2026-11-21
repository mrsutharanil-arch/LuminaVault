import SwiftUI
import UIKit

public struct VaultGalleryView: View {
    @ObservedObject public var viewModel: VaultViewModel
    @State private var selectedVaultItem: VaultItem? = nil
    @State private var showRestoreAlert: Bool = false
    @State private var showDeleteAlert: Bool = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3)
    ]
    
    public init(viewModel: VaultViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stealth Mode Banner if active
                if viewModel.vaultService.isStealthDecoyActive {
                    HStack {
                        Image(systemName: "eye.slash.fill")
                        Text("Stealth Decoy Vault Active")
                            .font(.caption.bold())
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Vault Header Banner
                GlassCard {
                    HStack(spacing: 14) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.yellow)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Secure Private Storage")
                                .font(.headline)
                            Text("\(viewModel.vaultService.vaultItems.count) files encrypted with AES-256")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal)
                
                if viewModel.vaultService.vaultItems.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "lock.slash")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("Private Vault is Empty")
                            .font(.headline)
                        Text("Select photos or videos in the Photos gallery and tap 'Lock Vault' to encrypt them with AES-256.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 40)
                } else {
                    // Vault Items Grid with real thumbnails
                    LazyVGrid(columns: columns, spacing: 3) {
                        ForEach(viewModel.vaultService.vaultItems) { item in
                            ZStack(alignment: .bottomLeading) {
                                if let thumb = viewModel.vaultService.loadVaultItemThumbnail(vaultItem: item) {
                                    Image(uiImage: thumb)
                                        .resizable()
                                        .aspectRatio(1, contentMode: .fill)
                                        .clipped()
                                } else {
                                    Rectangle()
                                        .fill(Color(UIColor.secondarySystemBackground))
                                        .aspectRatio(1, contentMode: .fit)
                                        .overlay(
                                            Image(systemName: item.mediaType.iconName)
                                                .font(.system(size: 26))
                                                .foregroundColor(.yellow.opacity(0.9))
                                        )
                                }
                                
                                // Tag or Badge
                                VStack(alignment: .leading) {
                                    HStack {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.yellow)
                                            .padding(4)
                                            .background(Color.black.opacity(0.6))
                                            .clipShape(Circle())
                                        Spacer()
                                    }
                                    Spacer()
                                    Text(item.originalFilename)
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color.black.opacity(0.6))
                                        .cornerRadius(3)
                                        .lineLimit(1)
                                }
                                .padding(4)
                            }
                            .cornerRadius(8)
                            .clipped()
                            .onTapGesture {
                                selectedVaultItem = item
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                }
                
                Spacer().frame(height: 80)
            }
            .padding(.vertical)
        }
        .sheet(item: $selectedVaultItem) { item in
            VaultItemDetailSheet(item: item, viewModel: viewModel)
        }
    }
}

public struct VaultItemDetailSheet: View {
    public let item: VaultItem
    @ObservedObject public var viewModel: VaultViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm: Bool = false
    @State private var showRestoreConfirm: Bool = false
    @State private var decryptedImage: UIImage? = nil
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Decrypted Preview Canvas
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black)
                        .frame(height: 280)
                    
                    if let image = decryptedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 280)
                            .cornerRadius(14)
                    } else if let thumb = viewModel.vaultService.loadVaultItemThumbnail(vaultItem: item) {
                        Image(uiImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 280)
                            .cornerRadius(14)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: item.mediaType.iconName)
                                .font(.system(size: 64))
                                .foregroundColor(.yellow)
                            Text(item.originalFilename)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("256-bit AES-GCM Encrypted")
                                .font(.caption)
                                .foregroundColor(.yellow.opacity(0.8))
                        }
                    }
                }
                .padding(.horizontal)
                
                List {
                    Section(header: Text("Vault Details")) {
                        HStack {
                            Text("Original File")
                            Spacer()
                            Text(item.originalFilename)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("File Size")
                            Spacer()
                            Text(item.formattedSize)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Locked Date")
                            Spacer()
                            Text(item.formattedLockDate)
                                .foregroundColor(.secondary)
                        }
                        if let notes = item.userNotes {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Private Notes")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                                Text(notes)
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                    Section {
                        Button(action: {
                            showRestoreConfirm = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                Text("Restore to iPhone Camera Roll")
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Button(role: .destructive, action: {
                            showDeleteConfirm = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Permanently Delete from Device")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Encrypted File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if item.mediaType == .image || item.mediaType == .livePhoto {
                    if let data = viewModel.vaultService.decryptVaultItemData(vaultItem: item),
                       let img = UIImage(data: data) {
                        self.decryptedImage = img
                    }
                }
            }
            .alert("Restore to Camera Roll?", isPresented: $showRestoreConfirm) {
                Button("Restore", role: .cancel) {
                    Task {
                        await viewModel.restoreItem(item: item)
                        dismiss()
                    }
                }
            } message: {
                Text("This file will be decrypted and returned to your iPhone Photos camera roll.")
            }
            .alert("Permanently Delete?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    viewModel.deletePermanently(item: item)
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone. The encrypted file will be completely erased from disk.")
            }
        }
    }
}
