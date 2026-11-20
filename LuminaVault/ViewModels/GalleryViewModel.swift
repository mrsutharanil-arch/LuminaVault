import Foundation
import SwiftUI
import Combine

public enum GalleryFilterSegment: String, CaseIterable, Identifiable {
    case all = "All"
    case photos = "Photos"
    case videos = "Videos"
    case live = "Live & Short"
    case favorites = "Favorites"
    
    public var id: String { rawValue }
}

public enum SortOrderOption: String, CaseIterable, Identifiable {
    case newestFirst = "Newest First"
    case oldestFirst = "Oldest First"
    case largestSize = "Largest File Size"
    
    public var id: String { rawValue }
}

@MainActor
public class GalleryViewModel: ObservableObject {
    @Published public var selectedFilter: GalleryFilterSegment = .all
    @Published public var sortOption: SortOrderOption = .newestFirst
    @Published public var searchText: String = ""
    @Published public var isSelectMode: Bool = false
    @Published public var selectedItemIds: Set<UUID> = []
    @Published public var selectedMediaForDetail: MediaItem? = nil
    @Published public var showFilterSheet: Bool = false
    @Published public var showMoveToVaultConfirmation: Bool = false
    
    private var scanner = PhotoLibraryScanner.shared
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        scanner.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }
    
    public var filteredItems: [MediaItem] {
        var items = scanner.allMediaItems
        
        // Filter by segment
        switch selectedFilter {
        case .all:
            break
        case .photos:
            items = items.filter { $0.mediaType == .image }
        case .videos:
            items = items.filter { $0.mediaType == .video }
        case .live:
            items = items.filter { $0.isShortPhoto || $0.mediaType == .livePhoto }
        case .favorites:
            items = items.filter { $0.isFavorite }
        }
        
        // Search filter
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchText.lowercased()
            items = items.filter {
                $0.filename.lowercased().contains(query) ||
                ($0.locationName?.lowercased().contains(query) ?? false) ||
                ($0.areaName?.lowercased().contains(query) ?? false) ||
                ($0.detectedText?.lowercased().contains(query) ?? false)
            }
        }
        
        // Sort
        switch sortOption {
        case .newestFirst:
            return items.sorted { $0.creationDate > $1.creationDate }
        case .oldestFirst:
            return items.sorted { $0.creationDate < $1.creationDate }
        case .largestSize:
            return items.sorted { $0.fileSize > $1.fileSize }
        }
    }
    
    public func toggleFavorite(for item: MediaItem) {
        if let idx = scanner.allMediaItems.firstIndex(where: { $0.id == item.id }) {
            scanner.allMediaItems[idx].isFavorite.toggle()
        }
    }
    
    public func toggleSelection(for item: MediaItem) {
        if selectedItemIds.contains(item.id) {
            selectedItemIds.remove(item.id)
        } else {
            selectedItemIds.insert(item.id)
        }
    }
    
    public func selectAll() {
        selectedItemIds = Set(filteredItems.map { $0.id })
    }
    
    public func clearSelection() {
        selectedItemIds.removeAll()
        isSelectMode = false
    }
    
    public func moveSelectedToVault() async {
        let itemsToMove = scanner.allMediaItems.filter { selectedItemIds.contains($0.id) }
        for item in itemsToMove {
            _ = await PrivateVaultService.shared.moveToPrivateVault(item: item, deleteOriginal: true)
        }
        clearSelection()
        FileManagerService.shared.recalculateStorage(
            with: scanner.allMediaItems,
            vaultItems: PrivateVaultService.shared.vaultItems
        )
    }
    
    public func backupSelectedToGooglePhotos() {
        let itemsToBackup = scanner.allMediaItems.filter { selectedItemIds.contains($0.id) }
        GooglePhotosService.shared.queueAllForBackup(items: itemsToBackup)
        clearSelection()
    }
}
