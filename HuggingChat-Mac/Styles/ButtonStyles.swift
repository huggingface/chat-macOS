//
//  ButtonStyles.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import SwiftUI

struct HighlightOnHover: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            
            .frame(width: 10, height: 10)
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .padding(.horizontal, 7)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.gray.opacity(0.2) : Color.clear)
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
            
    }
}

struct HighlightOnPress: ButtonStyle {
    let defaultBackground: Color
    
    init(defaultBackground: Color = .clear) {
        self.defaultBackground = defaultBackground
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 7)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed ? Color.gray.opacity(0.2) : defaultBackground)
            )
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == HighlightOnHover {
    static var highlightOnHover: HighlightOnHover {
        HighlightOnHover()
    }
    
    static var highlightOnPress: HighlightOnPress {
        HighlightOnPress()
    }
    
    static func highlightOnPress(defaultBackground: Color) -> HighlightOnPress {
        HighlightOnPress(defaultBackground: defaultBackground)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDelegate())
        .environment(CoordinatorModel())
}

