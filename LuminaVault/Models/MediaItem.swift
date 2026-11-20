import Foundation
import CoreLocation
import Photos
import SwiftUI

public enum MediaType: String, Codable, CaseIterable {
    case image
    case video
    case livePhoto
    
    public var iconName: String {
        switch self {
        case .image: return "photo"
        case .video: return "video.fill"
        case .livePhoto: return "livephoto"
        }
    }
}

public enum MediaSubtype: String, Codable, CaseIterable, Hashable {
    case screenshot
    case screenRecording
    case document
    case face
    case shortPhoto
    case burst
    case panorama
    case hdr
    case slowMo
    case timeLapse
    
    public var displayName: String {
        switch self {
        case .screenshot: return "Screenshot"
        case .screenRecording: return "Screen Recording"
        case .document: return "Document & OCR"
        case .face: return "Face & Portrait"
        case .shortPhoto: return "Short Clip / Live"
        case .burst: return "Burst Photo"
        case .panorama: return "Panorama"
        case .hdr: return "HDR"
        case .slowMo: return "Slo-Mo Video"
        case .timeLapse: return "Time-Lapse"
        }
    }
    
    public var iconName: String {
        switch self {
        case .screenshot: return "camera.viewfinder"
        case .screenRecording: return "record.circle"
        case .document: return "doc.text.viewfinder"
        case .face: return "person.crop.square.fill"
        case .shortPhoto: return "timer"
        case .burst: return "square.stack.3d.down.right.fill"
        case .panorama: return "pano"
        case .hdr: return "aqi.medium"
        case .slowMo: return "slowmo"
        case .timeLapse: return "timelapse"
        }
    }
}

public enum BackupStatus: Codable, Equatable {
    case notUploaded
    case queued
    case uploading(progress: Double)
    case completed
    case failed(reason: String)
    
    public var label: String {
        switch self {
        case .notUploaded: return "Not Backed Up"
        case .queued: return "Queued for Cloud"
        case .uploading(let progress): return "Backing up (\(Int(progress * 100))%)"
        case .completed: return "Backed up to Google Photos"
        case .failed(let reason): return "Failed: \(reason)"
        }
    }
    
    public var iconName: String {
        switch self {
        case .notUploaded: return "icloud.slash"
        case .queued: return "clock.arrow.2.circlepath"
        case .uploading: return "arrow.triangle.2.circlepath.icloud"
        case .completed: return "checkmark.icloud.fill"
        case .failed: return "exclamationmark.icloud"
        }
    }
    
    public var tintColor: Color {
        switch self {
        case .notUploaded: return .secondary
        case .queued: return .orange
        case .uploading: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
}

public struct DetectedFaceArea: Identifiable, Codable, Equatable {
    public let id: UUID
    public let boundingBox: CGRect // Normalized (0...1)
    public let qualityScore: Float
    public var personTag: String?
    
    public init(id: UUID = UUID(), boundingBox: CGRect, qualityScore: Float = 0.9, personTag: String? = nil) {
        self.id = id
        self.boundingBox = boundingBox
        self.qualityScore = qualityScore
        self.personTag = personTag
    }
}

public struct MediaItem: Identifiable, Equatable {
    public let id: UUID
    public var phAssetLocalId: String?
    public var filename: String
    public var mediaType: MediaType
    public var subtypes: Set<MediaSubtype>
    public var fileSize: Int64
    public var pixelWidth: Int
    public var pixelHeight: Int
    public var creationDate: Date
    public var duration: TimeInterval? // For videos
    public var coordinate: CLLocationCoordinate2D?
    public var locationName: String?
    public var areaName: String? // City, Landmark or Region
    public var isFavorite: Bool
    public var backupStatus: BackupStatus
    public var detectedFaces: [DetectedFaceArea]
    public var detectedText: String?
    public var isPrivate: Bool
    public var cameraModel: String?
    public var iso: Int?
    public var focalLength: Double?
    public var aperture: Double?
    
    public init(
        id: UUID = UUID(),
        phAssetLocalId: String? = nil,
        filename: String,
        mediaType: MediaType,
        subtypes: Set<MediaSubtype> = [],
        fileSize: Int64 = 0,
        pixelWidth: Int = 1920,
        pixelHeight: Int = 1080,
        creationDate: Date = Date(),
        duration: TimeInterval? = nil,
        coordinate: CLLocationCoordinate2D? = nil,
        locationName: String? = nil,
        areaName: String? = nil,
        isFavorite: Bool = false,
        backupStatus: BackupStatus = .notUploaded,
        detectedFaces: [DetectedFaceArea] = [],
        detectedText: String? = nil,
        isPrivate: Bool = false,
        cameraModel: String? = "iPhone 14 Main Camera (26mm f/1.5)",
        iso: Int? = 100,
        focalLength: Double? = 26.0,
        aperture: Double? = 1.5
    ) {
        self.id = id
        self.phAssetLocalId = phAssetLocalId
        self.filename = filename
        self.mediaType = mediaType
        self.subtypes = subtypes
        self.fileSize = fileSize
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.creationDate = creationDate
        self.duration = duration
        self.coordinate = coordinate
        self.locationName = locationName
        self.areaName = areaName
        self.isFavorite = isFavorite
        self.backupStatus = backupStatus
        self.detectedFaces = detectedFaces
        self.detectedText = detectedText
        self.isPrivate = isPrivate
        self.cameraModel = cameraModel
        self.iso = iso
        self.focalLength = focalLength
        self.aperture = aperture
    }
    
    public static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        return lhs.id == rhs.id && lhs.backupStatus == rhs.backupStatus && lhs.isFavorite == rhs.isFavorite && lhs.isPrivate == rhs.isPrivate
    }
    
    // Formatting Helpers
    public var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    public var formattedDimensions: String {
        "\(pixelWidth) × \(pixelHeight)"
    }
    
    public var formattedDuration: String? {
        guard let duration = duration, duration > 0 else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: creationDate)
    }
    
    public var isDocument: Bool {
        subtypes.contains(.document) || (detectedText != nil && !(detectedText?.isEmpty ?? true))
    }
    
    public var isScreenshot: Bool {
        subtypes.contains(.screenshot) || subtypes.contains(.screenRecording)
    }
    
    public var isFaceGroup: Bool {
        subtypes.contains(.face) || !detectedFaces.isEmpty
    }
    
    public var isShortPhoto: Bool {
        subtypes.contains(.shortPhoto) || subtypes.contains(.burst) || (mediaType == .video && (duration ?? 0) <= 15.0)
    }
}
