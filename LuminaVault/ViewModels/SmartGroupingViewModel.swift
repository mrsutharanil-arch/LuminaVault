import Foundation
import SwiftUI
import Combine

@MainActor
public class SmartGroupingViewModel: ObservableObject {
    @Published public var selectedGroup: SmartGroupType? = nil
    @Published public var isAnalyzingVision: Bool = false
    @Published public var videos: [MediaItem] = []
    @Published public var documents: [MediaItem] = []
    @Published public var faces: [MediaItem] = []
    @Published public var areaClusters: [GroupedCollection] = []
    @Published public var screenshots: [MediaItem] = []
    @Published public var shortPhotos: [MediaItem] = []
    
    // Sub-filters
    @Published public var documentSearchText: String = ""
    @Published public var selectedPersonFilter: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        refreshGroups()
        
        PhotoLibraryScanner.shared.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshGroups()
            }
            .store(in: &cancellables)
    }
    
    public func refreshGroups() {
        let allItems = PhotoLibraryScanner.shared.allMediaItems
        
        // 0. Videos
        self.videos = allItems.filter { $0.mediaType == .video }
        
        // 1. Documents
        self.documents = allItems.filter { $0.isDocument }
        
        // 2. Faces
        self.faces = allItems.filter { $0.isFaceGroup }
        
        // 3. Screenshots
        self.screenshots = allItems.filter { $0.isScreenshot }
        
        // 4. Short Photos (Live photos, bursts, short videos <= 15s)
        self.shortPhotos = allItems.filter { $0.isShortPhoto }
        
        // 5. Locations / Areas
        Task {
            await LocationGroupingService.shared.clusterByArea(items: allItems)
            self.areaClusters = LocationGroupingService.shared.locationClusters
        }
    }
    
    public var uniquePeopleNames: [String] {
        var names = Set<String>()
        for item in faces {
            for face in item.detectedFaces {
                if let tag = face.personTag {
                    names.insert(tag)
                }
            }
        }
        if names.isEmpty && !faces.isEmpty {
            return ["Portraits & Faces"]
        }
        return Array(names).sorted()
    }
    
    public var filteredDocuments: [MediaItem] {
        if documentSearchText.isEmpty {
            return documents
        }
        let query = documentSearchText.lowercased()
        return documents.filter {
            $0.filename.lowercased().contains(query) ||
            ($0.detectedText?.lowercased().contains(query) ?? false)
        }
    }
    
    public var filteredFaces: [MediaItem] {
        guard let selectedPerson = selectedPersonFilter else {
            return faces
        }
        return faces.filter { item in
            item.detectedFaces.contains { $0.personTag == selectedPerson } || selectedPerson == "Portraits & Faces"
        }
    }
    
    public func runDeepVisionScan() async {
        isAnalyzingVision = true
        await VisionGroupingEngine.shared.analyzeItems(items: PhotoLibraryScanner.shared.allMediaItems)
        refreshGroups()
        isAnalyzingVision = false
    }
    
    public func deleteOldScreenshots() {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let oldIds = Set(screenshots.filter { $0.creationDate < oneWeekAgo }.map { $0.id })
        PhotoLibraryScanner.shared.allMediaItems.removeAll { oldIds.contains($0.id) }
        PhotoLibraryScanner.shared.updateCategorizedCaches()
        refreshGroups()
    }
}
