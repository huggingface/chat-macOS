//
//  InputView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import SwiftUI

struct InputView: View {
    
    var cornerRadius: CGFloat = 14
    var isChatBarMode: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    @State private var inputText: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField("Message DeepSeek-R1", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(12)
                .frame(maxHeight: .infinity, alignment: .top)
            InputViewToolbar()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .frame(minHeight: 87)
        
        .background {
            if isChatBarMode {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThickMaterial)
                    .fill(colorScheme == .dark ? .black.opacity(0.4) : .white.opacity(0.4))
                    .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(.gray.opacity(0.5), style: StrokeStyle(lineWidth: 1)))
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.gray.opacity(0.5), lineWidth: 1)
//                    .fill(.ultraThickMaterial)
                    .fill(.quinary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDelegate())
        .environment(CoordinatorModel())
}

