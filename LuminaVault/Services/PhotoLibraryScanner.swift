import Foundation
import UIKit
import Photos
import PhotosUI
import SwiftUI
import CoreLocation
import AVFoundation

// MARK: - High-Performance Photo & Video Asset Loader
public class PhotoAssetLoader {
    public static let shared = PhotoAssetLoader()
    private let imageManager = PHCachingImageManager()
    private let thumbnailCache = NSCache<NSString, UIImage>()
    
    public init() {
        thumbnailCache.countLimit = 800
        thumbnailCache.totalCostLimit = 120 * 1024 * 1024 // 120 MB memory cache
    }
    
    public func cachedThumbnail(for assetId: String) -> UIImage? {
        return thumbnailCache.object(forKey: assetId as NSString)
    }
    
    @discardableResult
    public func loadThumbnail(
        for assetId: String,
        targetSize: CGSize = CGSize(width: 320, height: 320),
        completion: @escaping (UIImage?) -> Void
    ) -> PHImageRequestID? {
        if let cached = thumbnailCache.object(forKey: assetId as NSString) {
            completion(cached)
            return nil
        }
        
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = assets.firstObject else {
            completion(nil)
            return nil
        }
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        
        return imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { [weak self] image, _ in
            if let img = image {
                self?.thumbnailCache.setObject(img, forKey: assetId as NSString)
            }
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    public func loadFullImage(
        for assetId: String,
        completion: @escaping (UIImage?) -> Void
    ) -> PHImageRequestID? {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = assets.firstObject else {
            completion(nil)
            return nil
        }
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        
        return imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    public func loadAVPlayerItem(
        for assetId: String,
        completion: @escaping (AVPlayerItem?) -> Void
    ) {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = assets.firstObject, asset.mediaType == .video else {
            completion(nil)
            return
        }
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        
        imageManager.requestPlayerItem(forVideo: asset, options: options) { playerItem, _ in
            DispatchQueue.main.async {
                completion(playerItem)
            }
        }
    }
    
    public func loadOriginalData(
        for assetId: String,
        completion: @escaping (Data?, String?) -> Void
    ) {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = assets.firstObject else {
            completion(nil, nil)
            return
        }
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        
        imageManager.requestImageDataAndOrientation(for: asset, options: options) { data, uti, _, _ in
            DispatchQueue.main.async {
                completion(data, uti)
            }
        }
    }
    
    public func cancelRequest(_ requestId: PHImageRequestID) {
        imageManager.cancelImageRequest(requestId)
    }
}

// MARK: - Photo Library Scanner
@MainActor
public class PhotoLibraryScanner: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    public static let shared = PhotoLibraryScanner()
    
    @Published public var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published public var permissionDenied: Bool = false
    @Published public var isLimitedAccess: Bool = false
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
    @Published public var shortPhotos: [MediaItem] = []
    @Published public var documents: [MediaItem] = []
    @Published public var faces: [MediaItem] = []
    
    public override init() {
        super.init()
        checkAuthorization()
    }
    
    public func checkAuthorization() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch authorizationStatus {
        case .authorized:
            permissionDenied = false
            isLimitedAccess = false
            PHPhotoLibrary.shared().register(self)
            Task {
                await startFullLibraryScan()
            }
        case .limited:
            permissionDenied = false
            isLimitedAccess = true
            PHPhotoLibrary.shared().register(self)
            Task {
                await startFullLibraryScan()
            }
        case .denied, .restricted:
            permissionDenied = true
            isLimitedAccess = false
            allMediaItems = []
            updateCategorizedCaches()
        case .notDetermined:
            permissionDenied = false
            isLimitedAccess = false
            Task {
                _ = await requestPermission()
            }
        @unknown default:
            break
        }
    }
    
    public func requestPermission() async -> Bool {
        let status = await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                continuation.resume(returning: newStatus)
            }
        }
        
        self.authorizationStatus = status
        switch status {
        case .authorized:
            self.permissionDenied = false
            self.isLimitedAccess = false
            PHPhotoLibrary.shared().register(self)
            await startFullLibraryScan()
            return true
        case .limited:
            self.permissionDenied = false
            self.isLimitedAccess = true
            PHPhotoLibrary.shared().register(self)
            await startFullLibraryScan()
            return true
        case .denied, .restricted:
            self.permissionDenied = true
            self.isLimitedAccess = false
            self.allMediaItems = []
            self.updateCategorizedCaches()
            return false
        default:
            return false
        }
    }
    
    public func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    public func presentLimitedPicker() {
        if #available(iOS 14, *) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
            
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: topVC)
        }
    }
    
    public func startFullLibraryScan() async {
        guard !isScanning else { return }
        isScanning = true
        scanProgress = 0.0
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeCloudShared, .typeiTunesSynced]
        
        let allAssets = PHAsset.fetchAssets(with: fetchOptions)
        let total = allAssets.count
        
        if total == 0 {
            self.allMediaItems = []
            self.updateCategorizedCaches()
            self.isScanning = false
            self.scanProgress = 1.0
            return
        }
        
        var scannedItems: [MediaItem] = []
        let batchSize = 35
        
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
        
        // Auto-trigger background location clustering and storage calculation
        Task {
            await LocationGroupingService.shared.clusterByArea(items: scannedItems)
            FileManagerService.shared.recalculateStorage(
                with: scannedItems,
                vaultItems: PrivateVaultService.shared.vaultItems
            )
        }
    }
    
    private func convertPHAssetToMediaItem(asset: PHAsset) -> MediaItem {
        let mediaType: MediaType
        switch asset.mediaType {
        case .video:
            mediaType = .video
        case .image:
            if asset.mediaSubtypes.contains(.photoLive) {
                mediaType = .livePhoto
            } else {
                mediaType = .image
            }
        default:
            mediaType = .image
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
        if asset.representsBurst {
            subtypes.insert(.burst)
        }
        if asset.mediaSubtypes.contains(.videoHighFrameRate) {
            subtypes.insert(.slowMo)
        }
        if asset.mediaSubtypes.contains(.videoTimelapse) {
            subtypes.insert(.timeLapse)
        }
        if mediaType == .video && asset.duration <= 15.0 {
            subtypes.insert(.shortPhoto)
        }
        
        // Check standard iPhone aspect ratios for screen recordings
        if mediaType == .video && asset.pixelWidth > 0 && asset.pixelHeight > 0 {
            let ratio = Double(asset.pixelHeight) / Double(asset.pixelWidth)
            if (ratio > 2.14 && ratio < 2.2) || (ratio > 1.75 && ratio < 1.8) {
                subtypes.insert(.screenRecording)
            }
        }
        
        // Safe filename extraction without crash-prone KVC
        let resources = PHAssetResource.assetResources(for: asset)
        let filename = resources.first?.originalFilename ?? "IMG_\(abs(asset.localIdentifier.hashValue % 99999)).\(mediaType == .video ? "MOV" : "HEIC")"
        
        // File size estimation or resource size
        let resourceSize = (resources.first?.value(forKey: "fileSize") as? Int64) ?? 0
        let estimatedBytes: Int64
        if resourceSize > 0 {
            estimatedBytes = resourceSize
        } else if mediaType == .video {
            estimatedBytes = Int64(max(1.0, asset.duration) * 2_500_000) // ~20 Mbps bit rate
        } else {
            estimatedBytes = Int64(asset.pixelWidth * asset.pixelHeight * 3 / 8) // HEIC estimation
        }
        
        var item = MediaItem(
            phAssetLocalId: asset.localIdentifier,
            filename: filename,
            mediaType: mediaType,
            subtypes: subtypes,
            fileSize: max(100_000, estimatedBytes),
            pixelWidth: asset.pixelWidth,
            pixelHeight: asset.pixelHeight,
            creationDate: asset.creationDate ?? Date(),
            duration: mediaType == .video ? asset.duration : nil,
            coordinate: asset.location?.coordinate,
            isFavorite: asset.isFavorite
        )
        
        if let location = asset.location {
            item.areaName = "\(String(format: "%.2f", location.coordinate.latitude))°, \(String(format: "%.2f", location.coordinate.longitude))°"
        }
        
        return item
    }
    
    public func updateCategorizedCaches() {
        self.photos = allMediaItems.filter { $0.mediaType == .image || $0.mediaType == .livePhoto }
        self.videos = allMediaItems.filter { $0.mediaType == .video }
        self.livePhotos = allMediaItems.filter { $0.mediaType == .livePhoto }
        self.screenshots = allMediaItems.filter { $0.isScreenshot }
        self.favorites = allMediaItems.filter { $0.isFavorite }
        self.shortPhotos = allMediaItems.filter { $0.isShortPhoto }
        self.documents = allMediaItems.filter { $0.isDocument }
        self.faces = allMediaItems.filter { $0.isFaceGroup }
    }
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in
            await startFullLibraryScan()
        }
    }
}
