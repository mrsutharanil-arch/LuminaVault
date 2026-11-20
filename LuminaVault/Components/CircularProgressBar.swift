import SwiftUI

public struct CircularProgressBar: View {
    public let progress: Double
    public var lineWidth: CGFloat = 8
    public var tintColor: Color = .blue
    
    public init(progress: Double, lineWidth: CGFloat = 8, tintColor: Color = .blue) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.tintColor = tintColor
    }
    
    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(tintColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
        }
    }
}

public struct DynamicIslandBanner: View {
    public let icon: String
    public let title: String
    public let subtitle: String
    public var isPulse: Bool = true
    
    public init(icon: String, title: String, subtitle: String, isPulse: Bool = true) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isPulse = isPulse
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.cyan)
                .symbolEffect(.pulse, isActive: isPulse)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.92))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 24)
    }
}
