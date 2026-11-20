import SwiftUI

public struct VaultContainerView: View {
    @StateObject private var viewModel = VaultViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                if viewModel.vaultService.isUnlocked {
                    VaultGalleryView(viewModel: viewModel)
                } else {
                    VaultLockScreenView(viewModel: viewModel)
                }
            }
            .navigationTitle("Private Vault")
            .toolbar {
                if viewModel.vaultService.isUnlocked {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            viewModel.vaultService.lockVault()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                Text("Lock")
                            }
                            .font(.caption.bold())
                            .foregroundColor(.yellow)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.showSettingsSheet = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showSettingsSheet) {
                VaultSettingsView()
            }
        }
    }
}
