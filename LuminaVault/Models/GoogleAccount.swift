import Foundation
import SwiftUI

public struct GoogleAccount: Codable, Equatable {
    public var isSignedIn: Bool
    public var email: String?
    public var displayName: String?
    public var avatarURL: URL?
    public var accessToken: String?
    public var refreshToken: String?
    public var tokenExpirationDate: Date?
    public var storageTotalBytes: Int64 // Google One Quota, e.g. 15 GB
    public var storageUsedBytes: Int64
    
    public init(
        isSignedIn: Bool = false,
        email: String? = nil,
        displayName: String? = nil,
        avatarURL: URL? = nil,
        accessToken: String? = nil,
        refreshToken: String? = nil,
        tokenExpirationDate: Date? = nil,
        storageTotalBytes: Int64 = 15 * 1024 * 1024 * 1024,
        storageUsedBytes: Int64 = 4 * 1024 * 1024 * 1024
    ) {
        self.isSignedIn = isSignedIn
        self.email = email
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenExpirationDate = tokenExpirationDate
        self.storageTotalBytes = storageTotalBytes
        self.storageUsedBytes = storageUsedBytes
    }
    
    public var freeStorageBytes: Int64 {
        max(0, storageTotalBytes - storageUsedBytes)
    }
    
    public var usedPercentage: Double {
        guard storageTotalBytes > 0 else { return 0 }
        return Double(storageUsedBytes) / Double(storageTotalBytes)
    }
    
    public var formattedStorageSummary: String {
        let used = ByteCountFormatter.string(fromByteCount: storageUsedBytes, countStyle: .file)
        let total = ByteCountFormatter.string(fromByteCount: storageTotalBytes, countStyle: .file)
        return "\(used) of \(total) used"
    }
}

public enum BackupQuality: String, Codable, CaseIterable {
    case original = "Original Quality"
    case storageSaver = "Storage Saver (Compressed)"
    
    public var subtitle: String {
        switch self {
        case .original:
            return "Backs up full resolution without compression (takes Google One storage)"
        case .storageSaver:
            return "Slightly compresses images to 16MP and videos to 1080p to conserve quota"
        }
    }
}

public struct BackupSettings: Codable {
    public var autoBackupEnabled: Bool
    public var backupOnWiFiOnly: Bool
    public var backupVideos: Bool
    public var backupQuality: BackupQuality
    public var backupLivePhotos: Bool
    
    public init(
        autoBackupEnabled: Bool = true,
        backupOnWiFiOnly: Bool = true,
        backupVideos: Bool = true,
        backupQuality: BackupQuality = .original,
        backupLivePhotos: Bool = true
    ) {
        self.autoBackupEnabled = autoBackupEnabled
        self.backupOnWiFiOnly = backupOnWiFiOnly
        self.backupVideos = backupVideos
        self.backupQuality = backupQuality
        self.backupLivePhotos = backupLivePhotos
    }
}

public struct BackupTaskItem: Identifiable, Equatable {
    public let id: UUID
    public let mediaItemId: UUID
    public let filename: String
    public let fileSize: Int64
    public var progress: Double
    public var status: BackupStatus
    public var uploadToken: String?
    public var addedAt: Date
    
    public init(
        id: UUID = UUID(),
        mediaItemId: UUID,
        filename: String,
        fileSize: Int64,
        progress: Double = 0.0,
        status: BackupStatus = .queued,
        uploadToken: String? = nil,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.mediaItemId = mediaItemId
        self.filename = filename
        self.fileSize = fileSize
        self.progress = progress
        self.status = status
        self.uploadToken = uploadToken
        self.addedAt = addedAt
    }
    
    public static func == (lhs: BackupTaskItem, rhs: BackupTaskItem) -> Bool {
        lhs.id == rhs.id && lhs.progress == rhs.progress && lhs.status == rhs.status
    }
}
