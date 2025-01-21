//
//  ButtonStyles.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import SwiftUI

struct HighlightButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            
            .frame(width: 10, height: 10)
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .padding(.horizontal, 7)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.gray.opacity(0.3) : Color.clear)
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
            
    }
}

extension ButtonStyle where Self == HighlightButtonStyle {
    static var highlight: HighlightButtonStyle {
        HighlightButtonStyle()
    }
}

#Preview {
    ContentView()
}
