import SwiftUI

public struct BackupSettingsSheet: View {
    @ObservedObject public var service = GooglePhotosService.shared
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Google Cloud Sync Settings")) {
                    Toggle("Auto-Backup Library", isOn: $service.settings.autoBackupEnabled)
                    Toggle("Back up over Wi-Fi Only", isOn: $service.settings.backupOnWiFiOnly)
                    Toggle("Back up Videos & Clips", isOn: $service.settings.backupVideos)
                    Toggle("Back up Live Photos", isOn: $service.settings.backupLivePhotos)
                }
                
                Section(header: Text("Upload Quality"), footer: Text(service.settings.backupQuality.subtitle)) {
                    Picker("Upload Quality", selection: $service.settings.backupQuality) {
                        ForEach(BackupQuality.allCases, id: \.self) { quality in
                            Text(quality.rawValue).tag(quality)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                Section(header: Text("Account & Google One")) {
                    if service.account.isSignedIn {
                        HStack {
                            Text("Google Account")
                            Spacer()
                            Text(service.account.email ?? "Connected")
                                .foregroundColor(.secondary)
                        }
                        
                        Button(role: .destructive, action: {
                            service.signOut()
                            dismiss()
                        }) {
                            Text("Sign Out of Google Photos")
                        }
                    }
                }
            }
            .navigationTitle("Backup Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
