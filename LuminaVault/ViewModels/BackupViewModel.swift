import Foundation
import SwiftUI
import Combine

@MainActor
public class BackupViewModel: ObservableObject {
    @Published public var showSettingsSheet: Bool = false
    @Published public var showSignInSheet: Bool = false
    
    public var googlePhotos = GooglePhotosService.shared
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        googlePhotos.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }
    
    public var pendingCount: Int {
        let backedUpIds = Set(googlePhotos.backupQueue.filter { $0.status == .completed }.map { $0.mediaItemId })
        return PhotoLibraryScanner.shared.allMediaItems.filter { !backedUpIds.contains($0.id) && $0.backupStatus != .completed }.count
    }
    
    public func startFullCloudBackup() {
        let items = PhotoLibraryScanner.shared.allMediaItems
        googlePhotos.queueAllForBackup(items: items)
    }
    
    public func toggleBackupState() {
        if googlePhotos.isBackingUp {
            googlePhotos.pauseBackup()
        } else {
            googlePhotos.startBackupQueue()
        }
    }
}
