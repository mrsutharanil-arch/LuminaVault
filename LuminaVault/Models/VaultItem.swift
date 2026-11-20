import Foundation
import SwiftUI

public struct VaultItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public var originalFilename: String
    public var relativeEncryptedPath: String
    public var relativeThumbnailPath: String
    public var mediaType: MediaType
    public var fileSize: Int64
    public var lockedAt: Date
    public var originalCreationDate: Date
    public var userNotes: String?
    public var customTag: String?
    public var isDecryptedInMemory: Bool = false
    
    public init(
        id: UUID = UUID(),
        originalFilename: String,
        relativeEncryptedPath: String,
        relativeThumbnailPath: String,
        mediaType: MediaType,
        fileSize: Int64,
        lockedAt: Date = Date(),
        originalCreationDate: Date = Date(),
        userNotes: String? = nil,
        customTag: String? = nil
    ) {
        self.id = id
        self.originalFilename = originalFilename
        self.relativeEncryptedPath = relativeEncryptedPath
        self.relativeThumbnailPath = relativeThumbnailPath
        self.mediaType = mediaType
        self.fileSize = fileSize
        self.lockedAt = lockedAt
        self.originalCreationDate = originalCreationDate
        self.userNotes = userNotes
        self.customTag = customTag
    }
    
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    public var formattedLockDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lockedAt)
    }
}

public enum VaultLockTimeout: Int, Codable, CaseIterable {
    case immediately = 0
    case after1Minute = 60
    case after5Minutes = 300
    case after15Minutes = 900
    
    public var title: String {
        switch self {
        case .immediately: return "Immediately on Exit"
        case .after1Minute: return "After 1 Minute"
        case .after5Minutes: return "After 5 Minutes"
        case .after15Minutes: return "After 15 Minutes"
        }
    }
}

public struct VaultConfiguration: Codable {
    public var isBiometricsEnabled: Bool
    public var hasPasscodeSet: Bool
    public var autoLockTimeout: VaultLockTimeout
    public var stealthDecoyPinEnabled: Bool
    public var deleteOriginalFromCameraRoll: Bool
    public var breakInAlertsEnabled: Bool
    
    public init(
        isBiometricsEnabled: Bool = true,
        hasPasscodeSet: Bool = true,
        autoLockTimeout: VaultLockTimeout = .immediately,
        stealthDecoyPinEnabled: Bool = false,
        deleteOriginalFromCameraRoll: Bool = true,
        breakInAlertsEnabled: Bool = true
    ) {
        self.isBiometricsEnabled = isBiometricsEnabled
        self.hasPasscodeSet = hasPasscodeSet
        self.autoLockTimeout = autoLockTimeout
        self.stealthDecoyPinEnabled = stealthDecoyPinEnabled
        self.deleteOriginalFromCameraRoll = deleteOriginalFromCameraRoll
        self.breakInAlertsEnabled = breakInAlertsEnabled
    }
}
