import Foundation
import SwiftUI

@MainActor
public class FileManagerService: ObservableObject {
    public static let shared = FileManagerService()
    
    @Published public var storageBreakdown: StorageBreakdown = StorageBreakdown()
    @Published public var duplicateClusters: [DuplicateCluster] = []
    @Published public var largeMediaItems: [MediaItem] = []
    @Published public var isAnalyzingStorage: Bool = false
    
    public init() {}
    
    public func recalculateStorage(with items: [MediaItem], vaultItems: [VaultItem]) {
        isAnalyzingStorage = true
        
        let photosTotalBytes = items.reduce(0) { $0 + $1.fileSize }
        let vaultBytes = vaultItems.reduce(0) { $0 + $1.fileSize }
        
        let imagesBytes = items.filter { $0.mediaType == .image }.reduce(0) { $0 + $1.fileSize }
        let videosBytes = items.filter { $0.mediaType == .video }.reduce(0) { $0 + $1.fileSize }
        let screenshotBytes = items.filter { $0.isScreenshot }.reduce(0) { $0 + $1.fileSize }
        let documentBytes = items.filter { $0.isDocument }.reduce(0) { $0 + $1.fileSize }
        let livePhotoBytes = items.filter { $0.isShortPhoto }.reduce(0) { $0 + $1.fileSize }
        
        let categories: [StorageCategoryBreakdown] = [
            StorageCategoryBreakdown(title: "Photos (HEIC/RAW)", bytes: imagesBytes, count: items.filter { $0.mediaType == .image }.count, color: .blue, icon: "photo"),
            StorageCategoryBreakdown(title: "Videos (4K/HD)", bytes: videosBytes, count: items.filter { $0.mediaType == .video }.count, color: .purple, icon: "video.fill"),
            StorageCategoryBreakdown(title: "Screenshots & Grabs", bytes: screenshotBytes, count: items.filter { $0.isScreenshot }.count, color: .cyan, icon: "camera.viewfinder"),
            StorageCategoryBreakdown(title: "Documents & OCR", bytes: documentBytes, count: items.filter { $0.isDocument }.count, color: .orange, icon: "doc.text.viewfinder"),
            StorageCategoryBreakdown(title: "Short / Live Photos", bytes: livePhotoBytes, count: items.filter { $0.isShortPhoto }.count, color: .pink, icon: "livephoto"),
            StorageCategoryBreakdown(title: "Private Locked Vault", bytes: vaultBytes, count: vaultItems.count, color: .yellow, icon: "lock.shield.fill")
        ]
        
        // Mock phone capacity: 128 GB iPhone 14
        let totalPhone = Int64(128 * 1024 * 1024 * 1024)
        let otherAppsAndOS = Int64(48 * 1024 * 1024 * 1024)
        let used = otherAppsAndOS + photosTotalBytes + vaultBytes
        
        self.storageBreakdown = StorageBreakdown(
            totalPhoneStorageBytes: totalPhone,
            usedPhoneStorageBytes: used,
            photosTotalBytes: photosTotalBytes + vaultBytes,
            photosCount: items.count,
            videosCount: items.filter { $0.mediaType == .video }.count,
            categories: categories
        )
        
        // Find large media (> 8 MB)
        self.largeMediaItems = items.filter { $0.fileSize >= 8_000_000 }.sorted { $0.fileSize > $1.fileSize }
        
        // Find duplicates / burst groupings
        findDuplicates(items: items)
        
        self.isAnalyzingStorage = false
    }
    
    private func findDuplicates(items: [MediaItem]) {
        // Group items that have similar dimensions and close creation dates (within 3 seconds)
        var clusters: [DuplicateCluster] = []
        var visited = Set<UUID>()
        
        for item in items {
            if visited.contains(item.id) { continue }
            
            let matches = items.filter { other in
                other.id != item.id &&
                !visited.contains(other.id) &&
                other.pixelWidth == item.pixelWidth &&
                other.pixelHeight == item.pixelHeight &&
                abs(other.creationDate.timeIntervalSince(item.creationDate)) < 10
            }
            
            if !matches.isEmpty {
                visited.insert(item.id)
                for m in matches { visited.insert(m.id) }
                
                let cluster = DuplicateCluster(
                    title: "\(item.filename) (\(matches.count + 1) similar shots)",
                    originalItem: item,
                    duplicateItems: matches
                )
                clusters.append(cluster)
            }
        }
        
        self.duplicateClusters = clusters
    }
}
