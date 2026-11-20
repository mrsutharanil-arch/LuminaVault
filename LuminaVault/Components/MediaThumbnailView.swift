import SwiftUI

public struct MediaThumbnailView: View {
    public let item: MediaItem
    public var isSelected: Bool = false
    public var showSelectionCheckmark: Bool = false
    
    public init(item: MediaItem, isSelected: Bool = false, showSelectionCheckmark: Bool = false) {
        self.item = item
        self.isSelected = isSelected
        self.showSelectionCheckmark = showSelectionCheckmark
    }
    
    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Thumbnail Image / Mock Canvas
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundGradientForItem(item))
                .overlay(
                    VStack {
                        Spacer()
                        Image(systemName: item.mediaType.iconName)
                            .font(.system(size: 26))
                            .foregroundColor(.white.opacity(0.85))
                        Spacer()
                    }
                )
                .aspectRatio(1, contentMode: .fit)
                .clipped()
            
            // Top Badges
            VStack {
                HStack {
                    // Document Badge
                    if item.isDocument {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.text.fill")
                            Text("OCR")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    } else if item.isFaceGroup {
                        HStack(spacing: 3) {
                            Image(systemName: "person.crop.square.fill")
                            Text("\(item.detectedFaces.count)")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    } else if item.isScreenshot {
                        Text("SHOT")
                            .font(.system(size: 9, weight: .heavy))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.cyan.opacity(0.9))
                            .foregroundColor(.black)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    // Cloud Backup Status
                    Image(systemName: item.backupStatus.iconName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(item.backupStatus.tintColor)
                        .padding(4)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Circle())
                }
                .padding(5)
                
                Spacer()
                
                // Bottom Bar (Duration for video / Live badge)
                HStack {
                    if let duration = item.formattedDuration {
                        Text(duration)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    } else if item.mediaType == .livePhoto {
                        HStack(spacing: 2) {
                            Image(systemName: "livephoto")
                            Text("LIVE")
                        }
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    if item.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                            .shadow(radius: 2)
                    }
                }
                .padding(5)
            }
            
            // Selection Checkmark Overlay
            if showSelectionCheckmark {
                ZStack {
                    Color.black.opacity(isSelected ? 0.35 : 0.0)
                    
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(isSelected ? .blue : .white)
                                .shadow(radius: 3)
                                .padding(6)
                        }
                        Spacer()
                    }
                }
                .cornerRadius(10)
            }
        }
        .contentShape(Rectangle())
    }
    
    private func backgroundGradientForItem(_ item: MediaItem) -> LinearGradient {
        if item.isDocument {
            return LinearGradient(colors: [Color.yellow.opacity(0.4), Color.orange.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if item.isFaceGroup {
            return LinearGradient(colors: [Color.indigo.opacity(0.5), Color.purple.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if item.isScreenshot {
            return LinearGradient(colors: [Color.cyan.opacity(0.4), Color.blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if item.mediaType == .video {
            return LinearGradient(colors: [Color.purple.opacity(0.4), Color.black.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [Color.blue.opacity(0.4), Color.teal.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
