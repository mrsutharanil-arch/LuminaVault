import SwiftUI

@main
struct LuminaVaultApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appState = AppState.shared
    @StateObject private var scanner = PhotoLibraryScanner.shared
    @StateObject private var vaultService = PrivateVaultService.shared
    @StateObject private var googleService = GooglePhotosService.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .onChange(of: scenePhase) { newPhase in
                    switch newPhase {
                    case .background, .inactive:
                        // Auto-lock private vault upon app exit if configured
                        if vaultService.config.autoLockTimeout == .immediately {
                            vaultService.lockVault()
                        }
                    case .active:
                        break
                    @unknown default:
                        break
                    }
                }
        }
    }
}
