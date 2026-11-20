import Foundation
import SwiftUI

public struct StorageCategoryBreakdown: Identifiable {
    public let id = UUID()
    public let title: String
    public let bytes: Int64
    public let count: Int
    public let color: Color
    public let icon: String
    
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

public struct StorageBreakdown {
    public var totalPhoneStorageBytes: Int64 // e.g. 128 GB / 256 GB on iPhone 14
    public var usedPhoneStorageBytes: Int64
    public var photosTotalBytes: Int64
    public var photosCount: Int
    public var videosCount: Int
    public var categories: [StorageCategoryBreakdown]
    
    public init(
        totalPhoneStorageBytes: Int64 = 128 * 1024 * 1024 * 1024,
        usedPhoneStorageBytes: Int64 = 72 * 1024 * 1024 * 1024,
        photosTotalBytes: Int64 = 18 * 1024 * 1024 * 1024,
        photosCount: Int = 0,
        videosCount: Int = 0,
        categories: [StorageCategoryBreakdown] = []
    ) {
        self.totalPhoneStorageBytes = totalPhoneStorageBytes
        self.usedPhoneStorageBytes = usedPhoneStorageBytes
        self.photosTotalBytes = photosTotalBytes
        self.photosCount = photosCount
        self.videosCount = videosCount
        self.categories = categories
    }
    
    public var freePhoneStorageBytes: Int64 {
        max(0, totalPhoneStorageBytes - usedPhoneStorageBytes)
    }
    
    public var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: totalPhoneStorageBytes, countStyle: .file)
    }
    
    public var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: usedPhoneStorageBytes, countStyle: .file)
    }
    
    public var formattedPhotosTotal: String {
        ByteCountFormatter.string(fromByteCount: photosTotalBytes, countStyle: .file)
    }
    
    public var formattedFree: String {
        ByteCountFormatter.string(fromByteCount: freePhoneStorageBytes, countStyle: .file)
    }
    
    public var usedPercentage: Double {
        guard totalPhoneStorageBytes > 0 else { return 0 }
        return Double(usedPhoneStorageBytes) / Double(totalPhoneStorageBytes)
    }
}

public struct DuplicateCluster: Identifiable {
    public let id: UUID
    public let title: String
    public var originalItem: MediaItem
    public var duplicateItems: [MediaItem]
    
    public init(id: UUID = UUID(), title: String, originalItem: MediaItem, duplicateItems: [MediaItem]) {
        self.id = id
        self.title = title
        self.originalItem = originalItem
        self.duplicateItems = duplicateItems
    }
    
    public var recoverableBytes: Int64 {
        duplicateItems.reduce(0) { $0 + $1.fileSize }
    }
    
    public var recoverableFormatted: String {
        ByteCountFormatter.string(fromByteCount: recoverableBytes, countStyle: .file)
    }
}
