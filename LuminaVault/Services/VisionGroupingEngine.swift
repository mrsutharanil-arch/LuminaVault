import Foundation
import Vision
import UIKit
import Photos

@MainActor
public class VisionGroupingEngine: ObservableObject {
    public static let shared = VisionGroupingEngine()
    
    @Published public var isAnalyzing: Bool = false
    @Published public var analysisProgress: Double = 0.0
    @Published public var documentItems: [MediaItem] = []
    @Published public var faceItems: [MediaItem] = []
    @Published public var namedPeopleClusters: [String: [MediaItem]] = [:]
    
    public init() {}
    
    /// Analyzes media items using on-device Apple Vision (OCR & Face Detection)
    public func analyzeItems(items: [MediaItem]) async {
        guard !isAnalyzing else { return }
        isAnalyzing = true
        analysisProgress = 0.0
        
        var docs: [MediaItem] = []
        var faces: [MediaItem] = []
        var peopleMap: [String: [MediaItem]] = [:]
        
        let total = items.count
        guard total > 0 else {
            self.isAnalyzing = false
            return
        }
        
        for (index, var item) in items.enumerated() {
            // Only process still images
            if item.mediaType == .image || item.mediaType == .livePhoto {
                if let localId = item.phAssetLocalId {
                    // Load image for Vision processing
                    let image: UIImage? = await withCheckedContinuation { continuation in
                        PhotoAssetLoader.shared.loadThumbnail(for: localId, targetSize: CGSize(width: 600, height: 600)) { img in
                            continuation.resume(returning: img)
                        }
                    }
                    
                    if let img = image {
                        // 1. Text Recognition (OCR) for Documents / Receipts
                        if let recognized = await recognizeText(in: img), recognized.count >= 15 {
                            item.subtypes.insert(.document)
                            item.detectedText = recognized
                            docs.append(item)
                        }
                        
                        // 2. Face Detection for People / Portraits
                        let detectedFaces = await detectFaces(in: img)
                        if !detectedFaces.isEmpty {
                            item.subtypes.insert(.face)
                            item.detectedFaces = detectedFaces
                            faces.append(item)
                            
                            let personName = detectedFaces.first?.personTag ?? (detectedFaces.count > 1 ? "Group (\(detectedFaces.count) People)" : "Portraits")
                            peopleMap[personName, default: []].append(item)
                        }
                        
                        // Update in scanner master list if altered
                        if let masterIdx = PhotoLibraryScanner.shared.allMediaItems.firstIndex(where: { $0.id == item.id }) {
                            PhotoLibraryScanner.shared.allMediaItems[masterIdx] = item
                        }
                    }
                }
            }
            
            self.analysisProgress = Double(index + 1) / Double(total)
            if index % 4 == 0 {
                await Task.yield()
            }
        }
        
        self.documentItems = docs
        self.faceItems = faces
        self.namedPeopleClusters = peopleMap
        PhotoLibraryScanner.shared.updateCategorizedCaches()
        self.isAnalyzing = false
    }
    
    /// Perform real-time OCR on a UIImage using VNRecognizeTextRequest
    public func recognizeText(in image: UIImage) async -> String? {
        guard let cgImage = image.cgImage else { return nil }
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let text = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : text)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
    
    /// Detect faces and return normalized bounding boxes using VNDetectFaceRectanglesRequest
    public func detectFaces(in image: UIImage) async -> [DetectedFaceArea] {
        guard let cgImage = image.cgImage else { return [] }
        
        return await withCheckedContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNFaceObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let detected = observations.map { obs in
                    DetectedFaceArea(
                        boundingBox: obs.boundingBox,
                        qualityScore: 0.95,
                        personTag: nil
                    )
                }
                continuation.resume(returning: detected)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }
}
