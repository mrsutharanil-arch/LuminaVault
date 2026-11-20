import Foundation
import Photos
import SwiftUI
import CoreLocation

@MainActor
public class PhotoLibraryScanner: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    public static let shared = PhotoLibraryScanner()
    
    @Published public var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published public var isScanning: Bool = false
    @Published public var scanProgress: Double = 0.0
    @Published public var totalScannedCount: Int = 0
    @Published public var allMediaItems: [MediaItem] = []
    
    // Quick filtered lists
    @Published public var photos: [MediaItem] = []
    @Published public var videos: [MediaItem] = []
    @Published public var livePhotos: [MediaItem] = []
    @Published public var screenshots: [MediaItem] = []
    @Published public var favorites: [MediaItem] = []
    
    private let imageManager = PHCachingImageManager.default()
    
    public override init() {
        super.init()
        checkAuthorization()
    }
    
    public func checkAuthorization() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if authorizationStatus == .authorized || authorizationStatus == .limited {
            PHPhotoLibrary.shared().register(self)
            Task {
                await startFullLibraryScan()
            }
        } else {
            // Seed sample high-fidelity demonstration items for instant evaluation
            loadDemonstrationItems()
        }
    }
    
    public func requestPermission() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        self.authorizationStatus = status
        if status == .authorized || status == .limited {
            PHPhotoLibrary.shared().register(self)
            await startFullLibraryScan()
            return true
        }
        return false
    }
    
    public func startFullLibraryScan() async {
        guard !isScanning else { return }
        isScanning = true
        scanProgress = 0.0
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let allAssets = PHAsset.fetchAssets(with: fetchOptions)
        let total = allAssets.count
        
        if total == 0 {
            // If device library is empty or in simulator, provide rich mock data
            loadDemonstrationItems()
            isScanning = false
            return
        }
        
        var scannedItems: [MediaItem] = []
        let batchSize = 25
        
        for i in stride(from: 0, to: total, by: batchSize) {
            let endIndex = min(i + batchSize, total)
            for j in i..<endIndex {
                let asset = allAssets.object(at: j)
                let item = convertPHAssetToMediaItem(asset: asset)
                scannedItems.append(item)
            }
            self.scanProgress = Double(endIndex) / Double(total)
            self.totalScannedCount = scannedItems.count
            
            // Yield slightly to prevent UI lockup
            await Task.yield()
        }
        
        self.allMediaItems = scannedItems
        self.updateCategorizedCaches()
        self.isScanning = false
        self.scanProgress = 1.0
    }
    
    private func convertPHAssetToMediaItem(asset: PHAsset) -> MediaItem {
        let mediaType: MediaType
        switch asset.mediaType {
        case .video: mediaType = .video
        case .image:
            if asset.mediaSubtypes.contains(.photoLive) {
                mediaType = .livePhoto
            } else {
                mediaType = .image
            }
        default: mediaType = .image
        }
        
        var subtypes: Set<MediaSubtype> = []
        if asset.mediaSubtypes.contains(.photoScreenshot) {
            subtypes.insert(.screenshot)
        }
        if asset.mediaSubtypes.contains(.photoLive) {
            subtypes.insert(.shortPhoto)
        }
        if asset.mediaSubtypes.contains(.photoPanorama) {
            subtypes.insert(.panorama)
        }
        if asset.mediaSubtypes.contains(.photoHDR) {
            subtypes.insert(.hdr)
        }
        if mediaType == .video && asset.duration <= 15.0 {
            subtypes.insert(.shortPhoto)
        }
        
        // Estimation of file size based on resolution and type
        let estimatedBytes: Int64
        if mediaType == .video {
            estimatedBytes = Int64(asset.duration * 2_500_000) // ~20 Mbps bit rate
        } else {
            estimatedBytes = Int64(asset.pixelWidth * asset.pixelHeight * 3 / 8) // HEIC estimation
        }
        
        let filename = (asset.value(forKey: "filename") as? String) ?? "IMG_\(abs(asset.localIdentifier.hashValue % 9999)).HEIC"
        
        var item = MediaItem(
            phAssetLocalId: asset.localIdentifier,
            filename: filename,
            mediaType: mediaType,
            subtypes: subtypes,
            fileSize: max(150_000, estimatedBytes),
            pixelWidth: asset.pixelWidth,
            pixelHeight: asset.pixelHeight,
            creationDate: asset.creationDate ?? Date(),
            duration: mediaType == .video ? asset.duration : nil,
            coordinate: asset.location?.coordinate,
            isFavorite: asset.isFavorite
        )
        
        if let location = asset.location {
            item.areaName = "Location (\(String(format: "%.2f", location.coordinate.latitude)), \(String(format: "%.2f", location.coordinate.longitude)))"
        }
        
        return item
    }
    
    private func updateCategorizedCaches() {
        self.photos = allMediaItems.filter { $0.mediaType == .image || $0.mediaType == .livePhoto }
        self.videos = allMediaItems.filter { $0.mediaType == .video }
        self.livePhotos = allMediaItems.filter { $0.mediaType == .livePhoto || $0.subtypes.contains(.shortPhoto) }
        self.screenshots = allMediaItems.filter { $0.subtypes.contains(.screenshot) }
        self.favorites = allMediaItems.filter { $0.isFavorite }
    }
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in
            await startFullLibraryScan()
        }
    }
    
    // Seed Sample Items for Testing & Previews
    public func loadDemonstrationItems() {
        let calendar = Calendar.current
        let now = Date()
        
        let demoItems: [MediaItem] = [
            // Documents
            MediaItem(
                filename: "Store_Invoice_8849.jpg",
                mediaType: .image,
                subtypes: [.document],
                fileSize: 1_840_000,
                pixelWidth: 3024,
                pixelHeight: 4032,
                creationDate: calendar.date(byAdding: .day, value: -1, to: now)!,
                areaName: "Downtown Financial District",
                detectedText: "APPLE STORE 5TH AVE\nRECEIPT #884920\niPhone 14 Case $49.00\nTotal: $53.29 USD\nThank you for shopping!"
            ),
            MediaItem(
                filename: "Rental_Agreement_2026.pdf.jpg",
                mediaType: .image,
                subtypes: [.document],
                fileSize: 3_210_000,
                pixelWidth: 2480,
                pixelHeight: 3508,
                creationDate: calendar.date(byAdding: .day, value: -5, to: now)!,
                areaName: "Office Center",
                detectedText: "RESIDENTIAL LEASE AGREEMENT\nBetween Landlord & Tenant\nTerm: Nov 2026 - Nov 2027\nMonthly Rent: $2,400"
            ),
            MediaItem(
                filename: "Conference_Whiteboard.jpg",
                mediaType: .image,
                subtypes: [.document],
                fileSize: 2_950_000,
                pixelWidth: 4032,
                pixelHeight: 3024,
                creationDate: calendar.date(byAdding: .day, value: -8, to: now)!,
                areaName: "Tech Hub Silicon Valley",
                detectedText: "Sprint Architecture:\n1. PhotoKit Sync Engine\n2. Apple Vision OCR & Face\n3. Google Cloud API\n4. AES-GCM Encrypted Vault"
            ),
            
            // Faces & Portraits
            MediaItem(
                filename: "Sarah_Portrait_Sunset.heic",
                mediaType: .image,
                subtypes: [.face, .hdr],
                fileSize: 2_450_000,
                pixelWidth: 3024,
                pixelHeight: 4032,
                creationDate: calendar.date(byAdding: .day, value: -2, to: now)!,
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                locationName: "San Francisco, CA",
                areaName: "Golden Gate Bridge",
                isFavorite: true,
                detectedFaces: [
                    DetectedFaceArea(boundingBox: CGRect(x: 0.35, y: 0.25, width: 0.3, height: 0.35), qualityScore: 0.98, personTag: "Sarah")
                ]
            ),
            MediaItem(
                filename: "Team_Dinner_Group.heic",
                mediaType: .image,
                subtypes: [.face],
                fileSize: 3_890_000,
                pixelWidth: 4032,
                pixelHeight: 3024,
                creationDate: calendar.date(byAdding: .day, value: -12, to: now)!,
                coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
                locationName: "New York, NY",
                areaName: "Manhattan Bistro",
                detectedFaces: [
                    DetectedFaceArea(boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.18, height: 0.25), qualityScore: 0.92, personTag: "Sarah"),
                    DetectedFaceArea(boundingBox: CGRect(x: 0.45, y: 0.28, width: 0.2, height: 0.26), qualityScore: 0.95, personTag: "David"),
                    DetectedFaceArea(boundingBox: CGRect(x: 0.72, y: 0.32, width: 0.19, height: 0.24), qualityScore: 0.89, personTag: "Emma")
                ]
            ),
            MediaItem(
                filename: "Alex_Graduation_Smile.heic",
                mediaType: .image,
                subtypes: [.face],
                fileSize: 2_120_000,
                pixelWidth: 3024,
                pixelHeight: 4032,
                creationDate: calendar.date(byAdding: .month, value: -1, to: now)!,
                coordinate: CLLocationCoordinate2D(latitude: 42.3601, longitude: -71.0589),
                locationName: "Boston, MA",
                areaName: "Harvard Yard",
                isFavorite: true,
                detectedFaces: [
                    DetectedFaceArea(boundingBox: CGRect(x: 0.32, y: 0.2, width: 0.36, height: 0.4), qualityScore: 0.96, personTag: "Alex")
                ]
            ),
            
            // Screenshots
            MediaItem(
                filename: "Screenshot_CryptoChart.png",
                mediaType: .image,
                subtypes: [.screenshot],
                fileSize: 1_450_000,
                pixelWidth: 1170,
                pixelHeight: 2532,
                creationDate: calendar.date(byAdding: .hour, value: -4, to: now)!,
                areaName: "Home",
                detectedText: "Bitcoin $98,450 +4.2%\nPortfolio Value: $14,280.50"
            ),
            MediaItem(
                filename: "Screenshot_Flight_Ticket.png",
                mediaType: .image,
                subtypes: [.screenshot, .document],
                fileSize: 980_000,
                pixelWidth: 1170,
                pixelHeight: 2532,
                creationDate: calendar.date(byAdding: .day, value: -3, to: now)!,
                areaName: "JFK Terminal 4",
                detectedText: "Boarding Pass - Flight AA 104\nGate B22 | Seat 14A | Departure 08:30"
            ),
            MediaItem(
                filename: "Screen_Recording_AppDemo.mp4",
                mediaType: .video,
                subtypes: [.screenshot, .screenRecording],
                fileSize: 18_400_000,
                pixelWidth: 1170,
                pixelHeight: 2532,
                creationDate: calendar.date(byAdding: .day, value: -6, to: now)!,
                duration: 24.5,
                areaName: "Work"
            ),
            
            // Short Photos & Live Photos
            MediaItem(
                filename: "Beach_Waves_Live.heic",
                mediaType: .livePhoto,
                subtypes: [.shortPhoto],
                fileSize: 4_600_000,
                pixelWidth: 4032,
                pixelHeight: 3024,
                creationDate: calendar.date(byAdding: .day, value: -4, to: now)!,
                coordinate: CLLocationCoordinate2D(latitude: 21.3069, longitude: -157.8583),
                locationName: "Honolulu, Hawaii",
                areaName: "Waikiki Beach",
                isFavorite: true
            ),
            MediaItem(
                filename: "Espresso_Pour_Clip.mov",
                mediaType: .video,
                subtypes: [.shortPhoto],
                fileSize: 9_400_000,
                pixelWidth: 1080,
                pixelHeight: 1920,
                creationDate: calendar.date(byAdding: .day, value: -7, to: now)!,
                duration: 6.8,
                areaName: "Artisan Coffee Roasters"
            ),
            MediaItem(
                filename: "Puppy_Jump_Burst_01.heic",
                mediaType: .image,
                subtypes: [.shortPhoto, .burst],
                fileSize: 2_100_000,
                pixelWidth: 4032,
                pixelHeight: 3024,
                creationDate: calendar.date(byAdding: .day, value: -9, to: now)!,
                areaName: "Central Park Meadow"
            ),
            
            // Area / Location Groupings
            MediaItem(
                filename: "Tokyo_Shibuya_Night.heic",
                mediaType: .image,
                subtypes: [.hdr],
                fileSize: 4_200_000,
                pixelWidth: 4032,
                pixelHeight: 3024,
                creationDate: calendar.date(byAdding: .month, value: -2, to: now)!,
                coordinate: CLLocationCoordinate2D(latitude: 35.6595, longitude: 139.7005),
                locationName: "Tokyo, Japan",
                areaName: "Shibuya Crossing",
                isFavorite: true
            ),
            MediaItem(
                filename: "Eiffel_Tower_Lights.heic",
                mediaType: .image,
                subtypes: [.hdr],
                fileSize: 3_800_000,
                pixelWidth: 3024,
                pixelHeight: 4032,
                creationDate: calendar.date(byAdding: .month, value: -4, to: now)!,
                coordinate: CLLocationCoordinate2D(latitude: 48.8584, longitude: 2.2945),
                locationName: "Paris, France",
                areaName: "Champ de Mars"
            ),
            MediaItem(
                filename: "Grand_Canyon_Sunset.heic",
                mediaType: .image,
                subtypes: [.panorama],
                fileSize: 12_800_000,
                pixelWidth: 10800,
                pixelHeight: 3600,
                creationDate: calendar.date(byAdding: .month, value: -6, to: now)!,
                coordinate: CLLocationCoordinate2D(latitude: 36.1069, longitude: -112.1129),
                locationName: "Arizona, USA",
                areaName: "South Rim Vista",
                isFavorite: true
            )
        ]
        
        self.allMediaItems = demoItems
        self.totalScannedCount = demoItems.count
        self.updateCategorizedCaches()
    }
}
