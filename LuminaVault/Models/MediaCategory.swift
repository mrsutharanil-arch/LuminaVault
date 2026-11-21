import Foundation
import SwiftUI

public enum SmartGroupType: String, CaseIterable, Identifiable {
    case videos = "Videos & 4K Clips"
    case documents = "Documents & OCR"
    case faces = "Face Areas & People"
    case areas = "Area & Locations"
    case screenshots = "Screenshots & Clips"
    case shortPhotos = "Short Photos & Live"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .videos: return "video.fill"
        case .documents: return "doc.text.magnifyingglass"
        case .faces: return "person.crop.rectangle.stack"
        case .areas: return "mappin.and.ellipse"
        case .screenshots: return "camera.metering.matrix"
        case .shortPhotos: return "livephoto.play"
        }
    }
    
    public var gradientColors: [Color] {
        switch self {
        case .videos: return [Color.blue, Color.purple]
        case .documents: return [Color.orange, Color.red]
        case .faces: return [Color.purple, Color.indigo]
        case .areas: return [Color.teal, Color.blue]
        case .screenshots: return [Color.cyan, Color.blue]
        case .shortPhotos: return [Color.pink, Color.purple]
        }
    }
    
    public var description: String {
        switch self {
        case .videos:
            return "Original 4K, HD, Slo-Mo & Time-Lapse video recordings with duration breakdown"
        case .documents:
            return "Auto-scanned receipts, identity cards, printed text & whiteboards"
        case .faces:
            return "Facial detection clustering & portrait area isolation"
        case .areas:
            return "Geographic GPS clusters grouped by city, landmark, and region"
        case .screenshots:
            return "iOS screenshots, display grabs & screen recordings"
        case .shortPhotos:
            return "Apple Live Photos, quick bursts & short clips under 15 seconds"
        }
    }
}

public struct GroupedCollection: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let groupType: SmartGroupType
    public var items: [MediaItem]
    public var coverAsset: MediaItem? {
        items.first
    }
    
    public init(id: String, title: String, subtitle: String, groupType: SmartGroupType, items: [MediaItem]) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.groupType = groupType
        self.items = items
    }
    
    public var totalSizeFormatted: String {
        let totalBytes = items.reduce(0) { $0 + $1.fileSize }
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
}
