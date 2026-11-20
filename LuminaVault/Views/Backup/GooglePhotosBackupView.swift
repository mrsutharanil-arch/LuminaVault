import SwiftUI

public struct GooglePhotosBackupView: View {
    @StateObject private var viewModel = BackupViewModel()
    @ObservedObject private var googleService = GooglePhotosService.shared
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Google Account & Quota Card
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            if googleService.account.isSignedIn {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(colors: [.red, .yellow, .green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 48, height: 48)
                                        Text("G")
                                            .font(.title3.bold())
                                            .foregroundColor(.white)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(googleService.account.displayName ?? "Google Account")
                                            .font(.headline)
                                        Text(googleService.account.email ?? "")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    
                                    Button(action: {
                                        viewModel.showSettingsSheet = true
                                    }) {
                                        Image(systemName: "gearshape.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // Google One Storage Bar
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Google One Cloud Storage")
                                            .font(.caption.bold())
                                        Spacer()
                                        Text(googleService.account.formattedStorageSummary)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color(UIColor.tertiarySystemFill))
                                                .frame(height: 8)
                                            Capsule()
                                                .fill(Color.blue)
                                                .frame(width: max(8, CGFloat(googleService.account.usedPercentage) * geo.size.width), height: 8)
                                        }
                                    }
                                    .frame(height: 8)
                                }
                            } else {
                                // Sign in prompt
                                VStack(spacing: 12) {
                                    Image(systemName: "icloud.and.arrow.up")
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue)
                                    Text("Connect Google Photos")
                                        .font(.headline)
                                    Text("Automatically backup full resolution photos, Live Photos, and 4K videos directly to your Google Account.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                    
                                    Button(action: {
                                        Task {
                                            _ = await googleService.signInWithGoogle()
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "person.badge.key.fill")
                                            Text("Sign in with Google")
                                        }
                                        .font(.subheadline.bold())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Main Backup Action Card
                    if googleService.account.isSignedIn {
                        VStack(spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(googleService.isBackingUp ? "Backing up to Google Photos..." : "Ready to Cloud Sync")
                                        .font(.headline)
                                    Text("\(viewModel.pendingCount) items pending backup")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                Button(action: {
                                    viewModel.toggleBackupState()
                                }) {
                                    HStack {
                                        Image(systemName: googleService.isBackingUp ? "pause.fill" : "arrow.triangle.2.circlepath")
                                        Text(googleService.isBackingUp ? "Pause" : "Sync Now")
                                    }
                                    .font(.caption.bold())
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(googleService.isBackingUp ? Color.orange : Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                }
                            }
                            
                            // Progress bar
                            if googleService.isBackingUp {
                                VStack(alignment: .leading, spacing: 4) {
                                    if let currentFile = googleService.currentUploadingItemName {
                                        Text("Uploading: \(currentFile)")
                                            .font(.caption2.bold())
                                            .foregroundColor(.blue)
                                    }
                                    ProgressView(value: googleService.currentItemProgress, total: 1.0)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                }
                            }
                            
                            // One-tap Backup All
                            if !googleService.isBackingUp && viewModel.pendingCount > 0 {
                                Button(action: {
                                    viewModel.startFullCloudBackup()
                                }) {
                                    HStack {
                                        Image(systemName: "icloud.and.arrow.up.fill")
                                        Text("Backup All Phone Photos")
                                    }
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Active / Recent Upload Queue
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Upload Queue & History")
                                    .font(.headline)
                                Spacer()
                                Text("\(googleService.backupQueue.count) Tasks")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            
                            if googleService.backupQueue.isEmpty {
                                Text("Queue is empty. Tap 'Backup All Phone Photos' to begin cloud backup.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(googleService.backupQueue.reversed().prefix(10)) { task in
                                        HStack(spacing: 12) {
                                            Image(systemName: task.status.iconName)
                                                .foregroundColor(task.status.tintColor)
                                                .font(.system(size: 18))
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(task.filename)
                                                    .font(.subheadline.bold())
                                                    .lineLimit(1)
                                                Text(task.status.label)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Text(ByteCountFormatter.string(fromByteCount: task.fileSize, countStyle: .file))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(12)
                                        .background(Color(UIColor.secondarySystemGroupedBackground))
                                        .cornerRadius(12)
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer().frame(height: 80)
                }
                .padding(.vertical)
            }
            .navigationTitle("Google Photos Backup")
            .sheet(isPresented: $viewModel.showSettingsSheet) {
                BackupSettingsSheet()
            }
        }
    }
}
