//
//  HighlightButtonStyle.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 12/12/24.
//

import SwiftUI

struct MenuButtonStyle: MenuStyle {
    func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
            .labelsHidden()
            .menuStyle(.button)
            .buttonStyle(HighlightButtonStyle())
    }
}

struct HighlightButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 20, height: 10)
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.gray.opacity(0.3) : Color.clear)
            )
            .foregroundColor(.primary)
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct SpacedLabelStyle: LabelStyle {
    let spacing: CGFloat
    let alignment: VerticalAlignment
    
    init(spacing: CGFloat = 8, alignment: VerticalAlignment = .center) {
        self.spacing = spacing
        self.alignment = alignment
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: alignment, spacing: spacing) {
            configuration.icon
            configuration.title
        }
    }
}

#Preview("dark") {
    ChatView()
        .frame(height: 300)
        .environment(ModelManager())
        .environment(ConversationViewModel())
        .environment(AudioModelManager())
        .environment(MenuViewModel())
        .colorScheme(.dark)
}
