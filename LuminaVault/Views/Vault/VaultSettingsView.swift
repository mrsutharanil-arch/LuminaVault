import SwiftUI

public struct VaultSettingsView: View {
    @ObservedObject public var vaultService = PrivateVaultService.shared
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Biometrics & Security")) {
                    Toggle("Face ID / Touch ID Unlock", isOn: $vaultService.config.isBiometricsEnabled)
                    Toggle("Delete Original from Camera Roll", isOn: $vaultService.config.deleteOriginalFromCameraRoll)
                    Toggle("Break-in Attempt Alerts", isOn: $vaultService.config.breakInAlertsEnabled)
                }
                
                Section(header: Text("Auto-Lock Timeout")) {
                    Picker("Lock Timing", selection: $vaultService.config.autoLockTimeout) {
                        ForEach(VaultLockTimeout.allCases, id: \.self) { timeout in
                            Text(timeout.title).tag(timeout)
                        }
                    }
                }
                
                Section(header: Text("Stealth & Panic Modes"), footer: Text("Entering PIN '9999' unlocks a clean decoy gallery with zero private photos visible.")) {
                    Toggle("Enable Stealth Decoy PIN (9999)", isOn: $vaultService.config.stealthDecoyPinEnabled)
                }
                
                Section(header: Text("Encryption Specification")) {
                    HStack {
                        Text("Cipher Standard")
                        Spacer()
                        Text("AES-GCM 256-bit")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Storage Sandbox")
                        Spacer()
                        Text("Application Support (Excluded from iCloud)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Vault Security Settings")
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
