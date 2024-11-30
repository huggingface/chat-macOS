//
//  RolodexView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 9/30/24.
//

import SwiftUI

public struct CardStack<Content:View>: View {
    
    private let views: [Content]
    @State private var dragProgress = 0.0
    @State private var containerSize = CGSize.zero
    @Binding var selectedIndex: Int
    @State private var isAnimating = false
    @State private var animationProgress: CGFloat = 0
    
    @AppStorage("isLocalGeneration") private var isLocalGeneration: Bool = false
    
    public init(_ views: [Content], selectedIndex: Binding<Int>) {
            self.views = views
            self._selectedIndex = selectedIndex
        }
    
    public var body: some View {
        ZStack {
            ForEach(0..<views.count, id: \.self) { index in
                views[index]
                    .zIndex(zIndex(for: index))
                    .offset(y: yOffset(for: index))
                    .scaleEffect(scale(for: index), anchor: .center)
                    .opacity(opacity(for: index))
            }
        }
        .measure($containerSize)
        .onChange(of: isLocalGeneration) { oldValue, newValue in
            simulateDrag()
        }
    }
    
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                self.dragProgress = -(value.translation.height / containerSize.height)
            }
            .onEnded { value in
                snapToNearestIndex()
            }
    }
    
    func simulateDrag() {
        guard !isAnimating else { return }
        isAnimating = true
        let isLastCard = selectedIndex == views.count - 1
        withAnimation(.easeInOut(duration: 0.3)) {
            self.dragProgress = isLastCard ? -0.4: 0.4
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            snapToNearestIndex()
            isAnimating = false
        }
    }
    
    func snapToNearestIndex() {
        let threshold = 0.3
        if abs(dragProgress) < threshold {
            withAnimation(.bouncy) {
                self.dragProgress = 0.0
            }
        } else {
            let direction = dragProgress < 0 ? -1 : 1
            withAnimation(.smooth(duration: 0.25)) {
                go(to: selectedIndex + direction)
            }
        }
    }
    
    func go(to index: Int) {
        let maxIndex = views.count - 1
        if index > maxIndex {
            self.selectedIndex = maxIndex
        } else if index < 0 {
            self.selectedIndex = 0
        } else {
            self.selectedIndex = index
        }
        self.dragProgress = 0
    }
    
    
    var progressIndex: Double {
        dragProgress + Double(selectedIndex)
    }
    
    func currentPosition(for index: Int) -> Double {
        progressIndex - Double(index)
    }
    
    func zIndex(for index: Int) -> Double {
        let position = currentPosition(for: index)
        return -abs(position)
    }
    
    func yOffset(for index: Int) -> Double {
        let padding = containerSize.height / 10
        let y = (Double(index) - progressIndex) * padding
        let maxIndex = views.count - 1
        // position > 0 && position < 0.99 && index < maxIndex
        if index == selectedIndex && progressIndex < Double(maxIndex) && progressIndex > 0 {
            return y * swingOutMultiplier
        }
        return y
    }
    
    var swingOutMultiplier: Double {
        return abs(sin(Double.pi * progressIndex) * 25)
    }
    
    func scale(for index: Int) -> CGFloat {
        return 1.0 - (0.3 * abs(currentPosition(for: index)))
    }
    
    func opacity(for index: Int) -> CGFloat {
        return 1.0
    }
    
    func rotation(for index: Int) -> Double {
        return -currentPosition(for: index) * 2
    }
    
}

extension View {
    
    /// Measures the geometry of the attached view.
    func measure(_ size: Binding<CGSize>) -> some View {
        self.background {
            GeometryReader { reader in
                Color.clear.preference(
                    key: ViewSizePreferenceKey.self,
                    value: reader.size
                )
            }
        }
        .onPreferenceChange(ViewSizePreferenceKey.self) {
            size.wrappedValue = $0 ?? .zero
        }
    }
}

struct ViewSizePreferenceKey: PreferenceKey {
    
    static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
        value = nextValue() ?? value
    }
    
    static var defaultValue: CGSize? = nil
}
