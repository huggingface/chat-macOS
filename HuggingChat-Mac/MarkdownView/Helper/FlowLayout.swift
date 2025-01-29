import SwiftUI

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct FlowLayout: Layout {
    typealias Cache = [ViewRect]
    
    var verticleSpacing: CGFloat = 0
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        guard subviews.count != 0 else { return .zero }
        guard let containerWidth = proposal.width else { return .zero }

        let proposal = ProposedViewSize(width: containerWidth, height: nil)
        
        var size = CGSize.zero
        var x = CGFloat.zero
        var y = CGFloat.zero
        var rowHeight = CGFloat.zero
        var rects = [ViewRect]()
        var startIndex = 0
        
        subviews.indices.forEach {
            let subviewSize = subviews[$0].sizeThatFits(proposal)

            if x + subviewSize.width > containerWidth {
                // Adjust the y position of subviews and cache them
                adjustAndCache(&rects, rowHeight: rowHeight, to: &cache, startIndex: startIndex)
                startIndex = $0
                
                // This element cannot be accommodated horizontally
                // Increase the height
                y += rowHeight + verticleSpacing
                x = .zero
                rowHeight = subviewSize.height
            }
            
            if containerWidth.isNormal {
                // Prepare ViewRects and cache them when we are getting the ideal width
                let viewRect = ViewRect(
                    element: subviews[$0],
                    leadingPoint: CGPoint(x: x, y: y),
                    size: subviewSize
                )
                rects.append(viewRect)
            }
            
            rowHeight = max(subviewSize.height, rowHeight)
            x += subviewSize.width
            size.width = min(subviewSize.width + size.width, containerWidth)
            size.height = max(y + subviewSize.height, size.height)
        }
        
        // Add remaining rects
        if !rects.isEmpty {
            adjustAndCache(&rects, rowHeight: rowHeight, to: &cache, startIndex: startIndex)
        }
        
        return size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        for rect in cache {
            let proposal = ProposedViewSize(rect.size)
            let position = CGPoint(x: rect.leadingPoint.x + bounds.minX,
                                   y: rect.leadingPoint.y + bounds.minY)
            rect.element.place(at: position, anchor: .leading, proposal: proposal)
        }
    }
    
    func makeCache(subviews: Subviews) -> Cache {
        guard let firstSubview = subviews.first else { return [] }
        return [ViewRect](repeating: ViewRect(element: firstSubview, leadingPoint: .zero, size: .zero), count: subviews.count)
    }
    
    private func adjustAndCache(
        _ rects: inout Cache, rowHeight: CGFloat,
        to cache: inout Cache, startIndex: Int
    ) {
        for index in rects.indices {
            rects[index].leadingPoint.y += rowHeight / 2
            if index + startIndex < cache.count {
                cache[startIndex + index] = rects[index]
            }
        }
        rects.removeAll()
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension FlowLayout {
    struct ViewRect: Equatable {
        var element: LayoutSubviews.Element
        var leadingPoint: CGPoint
        var size: CGSize
    }
}

