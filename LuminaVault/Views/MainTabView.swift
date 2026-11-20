import SwiftUI

public enum MainTab: Int, CaseIterable, Identifiable {
    case gallery = 0
    case smartGroups = 1
    case fileManager = 2
    case cloudBackup = 3
    case privateVault = 4
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .gallery: return "Photos"
        case .smartGroups: return "Smart Groups"
        case .fileManager: return "File Manager"
        case .cloudBackup: return "Backup"
        case .privateVault: return "Private Vault"
        }
    }
    
    public var icon: String {
        switch self {
        case .gallery: return "photo.on.rectangle.angled"
        case .smartGroups: return "sparkles.rectangle.stack.fill"
        case .fileManager: return "folder.fill.badge.gearshape"
        case .cloudBackup: return "icloud.and.arrow.up.fill"
        case .privateVault: return "lock.shield.fill"
        }
    }
}

public struct MainTabView: View {
    @State private var selectedTab: MainTab = .gallery
    @ObservedObject private var googleService = GooglePhotosService.shared
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            GalleryView()
                .tabItem {
                    Label(MainTab.gallery.title, systemImage: MainTab.gallery.icon)
                }
                .tag(MainTab.gallery)
            
            SmartGroupsHubView()
                .tabItem {
                    Label(MainTab.smartGroups.title, systemImage: MainTab.smartGroups.icon)
                }
                .tag(MainTab.smartGroups)
            
            FileManagerView()
                .tabItem {
                    Label(MainTab.fileManager.title, systemImage: MainTab.fileManager.icon)
                }
                .tag(MainTab.fileManager)
            
            GooglePhotosBackupView()
                .tabItem {
                    Label(MainTab.cloudBackup.title, systemImage: MainTab.cloudBackup.icon)
                }
                .badge(googleService.isBackingUp ? "Syncing" : nil)
                .tag(MainTab.cloudBackup)
            
            VaultContainerView()
                .tabItem {
                    Label(MainTab.privateVault.title, systemImage: MainTab.privateVault.icon)
                }
                .tag(MainTab.privateVault)
        }
        .tint(.blue)
    }
}
