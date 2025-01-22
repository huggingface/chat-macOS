//
//  ButtonLabelAnimation.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import SwiftUI

struct ButtonStateAnimation: View {
    
    var buttonText: String = "Search"
    var buttonImage: String = "globe"
    var tintColor: Color = .blue
    var onPress: () -> Void = {}
    
    @State var toggleAlternateAppearance: Bool = false
    @State private var isHovered = false
    
    var body: some View {
        Button {
            onPress()
            withAnimation(.spring(duration: 0.2), {
                toggleAlternateAppearance.toggle()
            })
        } label: {
            HStack(spacing: 5) {
                Image(systemName: buttonImage)
                
                if toggleAlternateAppearance {
                    Text(buttonText)
                        .font(.subheadline)
                        
                        .transition(.scale(0.8, anchor: .leading).combined(with: .opacity))
                }
            }.foregroundStyle(toggleAlternateAppearance ? tintColor:.primary)
               
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 5)
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.gray.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .background {
            if toggleAlternateAppearance {
                RoundedRectangle(cornerRadius: 6)
                    .fill(tintColor.opacity(0.1))
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDelegate())
}
