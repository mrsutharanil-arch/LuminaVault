import Foundation
import CoreLocation
import MapKit

@MainActor
public class LocationGroupingService: ObservableObject {
    public static let shared = LocationGroupingService()
    
    @Published public var locationClusters: [GroupedCollection] = []
    @Published public var isClustering: Bool = false
    
    private let geocoder = CLGeocoder()
    
    public init() {}
    
    public func clusterByArea(items: [MediaItem]) async {
        isClustering = true
        
        var areaDict: [String: [MediaItem]] = [:]
        
        for item in items {
            if let areaName = item.areaName {
                areaDict[areaName, default: []].append(item)
            } else if let locName = item.locationName {
                areaDict[locName, default: []].append(item)
            } else if item.coordinate != nil {
                areaDict["GPS Tagged Places", default: []].append(item)
            }
        }
        
        var collections: [GroupedCollection] = []
        for (area, clusterItems) in areaDict {
            let collection = GroupedCollection(
                id: "area_\(area.replacingOccurrences(of: " ", with: "_"))",
                title: area,
                subtitle: "\(clusterItems.count) photos & videos",
                groupType: .areas,
                items: clusterItems
            )
            collections.append(collection)
        }
        
        // Sort with most populated areas first
        self.locationClusters = collections.sorted { $0.items.count > $1.items.count }
        self.isClustering = false
    }
}
