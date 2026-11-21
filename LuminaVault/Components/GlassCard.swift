import SwiftUI
import UIKit

public struct GlassCard<Content: View>: View {
    public let cornerRadius: CGFloat
    public let content: () -> Content
    
    public init(cornerRadius: CGFloat = 18, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }
    
    public var body: some View {
        content()
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(UIColor.secondarySystemGroupedBackground).opacity(0.85))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
            )
    }
}
