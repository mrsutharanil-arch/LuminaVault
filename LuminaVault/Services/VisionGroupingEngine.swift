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
    
    /// Analyzes an array of media items using on-device Apple Vision
    public func analyzeItems(items: [MediaItem]) async {
        guard !isAnalyzing else { return }
        isAnalyzing = true
        analysisProgress = 0.0
        
        var docs: [MediaItem] = []
        var faces: [MediaItem] = []
        var peopleMap: [String: [MediaItem]] = [:]
        
        let total = items.count
        for (index, var item) in items.enumerated() {
            // Check if item has document attributes
            if item.isDocument {
                docs.append(item)
            }
            
            // Check face attributes
            if item.isFaceGroup {
                faces.append(item)
                for face in item.detectedFaces {
                    let personName = face.personTag ?? "Unassigned Person"
                    peopleMap[personName, default: []].append(item)
                }
            }
            
            self.analysisProgress = Double(index + 1) / Double(max(1, total))
            if index % 5 == 0 {
                await Task.yield()
            }
        }
        
        self.documentItems = docs
        self.faceItems = faces
        self.namedPeopleClusters = peopleMap
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
                
                continuation.resume(returning: text.isEmpty ? nil : text)
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
