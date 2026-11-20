import SwiftUI

public struct FilterSegmentBar: View {
    @Binding public var selectedSegment: GalleryFilterSegment
    
    public init(selectedSegment: Binding<GalleryFilterSegment>) {
        self._selectedSegment = selectedSegment
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GalleryFilterSegment.allCases) { segment in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSegment = segment
                        }
                    }) {
                        Text(segment.rawValue)
                            .font(.system(size: 13, weight: selectedSegment == segment ? .bold : .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(selectedSegment == segment ? Color.blue : Color(UIColor.secondarySystemFill))
                            )
                            .foregroundColor(selectedSegment == segment ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }
}
