import SwiftUI
import MapKit

public struct ExifDetailSheet: View {
    public let item: MediaItem
    @Environment(\.dismiss) private var dismiss
    
    public init(item: MediaItem) {
        self.item = item
    }
    
    public var body: some View {
        NavigationView {
            List {
                // Section 1: File Information
                Section(header: Text("File Specification")) {
                    HStack {
                        Label("File Name", systemImage: "doc")
                        Spacer()
                        Text(item.filename)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Dimensions", systemImage: "aspectratio")
                        Spacer()
                        Text(item.formattedDimensions)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("File Size", systemImage: "internaldrive")
                        Spacer()
                        Text(item.formattedFileSize)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Created", systemImage: "calendar")
                        Spacer()
                        Text(item.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Section 2: Camera & Optics (iPhone 14)
                Section(header: Text("Camera Hardware & Exposure")) {
                    HStack {
                        Label("Device", systemImage: "iphone")
                        Spacer()
                        Text(item.cameraModel ?? "iPhone 14")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let focal = item.focalLength {
                        HStack {
                            Label("Focal Length", systemImage: "camera.aperture")
                            Spacer()
                            Text("\(String(format: "%.1f", focal)) mm")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let aperture = item.aperture {
                        HStack {
                            Label("Aperture", systemImage: "circle.circle")
                            Spacer()
                            Text("ƒ/\(String(format: "%.1f", aperture))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let iso = item.iso {
                        HStack {
                            Label("ISO Sensitivity", systemImage: "sun.max")
                            Spacer()
                            Text("ISO \(iso)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Section 3: Geolocation
                if let area = item.areaName ?? item.locationName {
                    Section(header: Text("Location & Area")) {
                        HStack {
                            Label("Area", systemImage: "mappin.and.ellipse")
                            Spacer()
                            Text(area)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let coord = item.coordinate {
                            HStack {
                                Label("GPS Coordinates", systemImage: "location")
                                Spacer()
                                Text(String(format: "%.4f, %.4f", coord.latitude, coord.longitude))
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Section 4: AI & Vision Detections
                if item.isDocument || item.isFaceGroup {
                    Section(header: Text("On-Device Vision Analysis")) {
                        if item.isDocument {
                            HStack {
                                Label("Classification", systemImage: "doc.text.magnifyingglass")
                                Spacer()
                                Text("Document / Receipt")
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        if item.isFaceGroup {
                            HStack {
                                Label("Faces Detected", systemImage: "person.crop.square")
                                Spacer()
                                Text("\(item.detectedFaces.count) Faces")
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }
            }
            .navigationTitle("File & EXIF Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
