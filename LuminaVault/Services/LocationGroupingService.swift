import Foundation
import CoreLocation
import MapKit

@MainActor
public class LocationGroupingService: ObservableObject {
    public static let shared = LocationGroupingService()
    
    @Published public var locationClusters: [GroupedCollection] = []
    @Published public var isClustering: Bool = false
    
    private let geocoder = CLGeocoder()
    private var geocodeCache: [String: String] = [:]
    
    public init() {}
    
    public func clusterByArea(items: [MediaItem]) async {
        isClustering = true
        
        var areaDict: [String: [MediaItem]] = [:]
        
        // Group items by coordinate key (rounded to ~0.02 deg ~ 2km)
        var coordinateGroups: [String: (CLLocation, [MediaItem])] = [:]
        
        for item in items {
            if let locName = item.locationName, !locName.isEmpty {
                areaDict[locName, default: []].append(item)
            } else if let coord = item.coordinate {
                let key = "\(String(format: "%.2f", coord.latitude)),\(String(format: "%.2f", coord.longitude))"
                if let cachedName = geocodeCache[key] {
                    areaDict[cachedName, default: []].append(item)
                } else {
                    if coordinateGroups[key] == nil {
                        coordinateGroups[key] = (CLLocation(latitude: coord.latitude, longitude: coord.longitude), [item])
                    } else {
                        coordinateGroups[key]?.1.append(item)
                    }
                }
            }
        }
        
        // Reverse-geocode unique location clusters (up to 12 clusters to prevent geocoder throttling)
        let sortedCoordGroups = coordinateGroups.values.sorted { $0.1.count > $1.1.count }.prefix(12)
        for (location, clusterItems) in sortedCoordGroups {
            let key = "\(String(format: "%.2f", location.coordinate.latitude)),\(String(format: "%.2f", location.coordinate.longitude))"
            var resolvedName: String? = nil
            
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let placemark = placemarks.first {
                    var components: [String] = []
                    if let locality = placemark.locality {
                        components.append(locality)
                    }
                    if let adminArea = placemark.administrativeArea {
                        components.append(adminArea)
                    } else if let country = placemark.country {
                        components.append(country)
                    }
                    
                    if !components.isEmpty {
                        resolvedName = components.joined(separator: ", ")
                    }
                }
            } catch {
                // Network or geocode limit
                resolvedName = nil
            }
            
            let finalName = resolvedName ?? "Area (\(key))"
            geocodeCache[key] = finalName
            areaDict[finalName, default: []].append(contentsOf: clusterItems)
            
            // Short yield between geocode calls
            try? await Task.sleep(nanoseconds: 100_000_000)
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
