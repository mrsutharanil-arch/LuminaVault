import Foundation
import SwiftUI
import Combine

@MainActor
public class FileManagerViewModel: ObservableObject {
    @Published public var selectedItemForExif: MediaItem? = nil
    @Published public var showDuplicateCleaner: Bool = false
    @Published public var showLargeFilesView: Bool = false
    @Published public var isCleaning: Bool = false
    @Published public var cleanedBytes: Int64 = 0
    
    public var fileManagerService = FileManagerService.shared
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        fileManagerService.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        
        refreshStorage()
    }
    
    public func refreshStorage() {
        fileManagerService.recalculateStorage(
            with: PhotoLibraryScanner.shared.allMediaItems,
            vaultItems: PrivateVaultService.shared.vaultItems
        )
    }
    
    public func cleanAllDuplicates() async {
        isCleaning = true
        var freed: Int64 = 0
        
        for cluster in fileManagerService.duplicateClusters {
            let dupeIds = Set(cluster.duplicateItems.map { $0.id })
            freed += cluster.recoverableBytes
            PhotoLibraryScanner.shared.allMediaItems.removeAll { dupeIds.contains($0.id) }
        }
        
        try? await Task.sleep(nanoseconds: 600_000_000)
        self.cleanedBytes += freed
        self.refreshStorage()
        self.isCleaning = false
    }
    
    public func deleteItem(item: MediaItem) {
        PhotoLibraryScanner.shared.allMediaItems.removeAll { $0.id == item.id }
        self.refreshStorage()
    }
}
