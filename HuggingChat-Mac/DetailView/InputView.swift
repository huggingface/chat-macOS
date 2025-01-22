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
    
    @State private var inputText: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField("Message ChatGPT", text: $inputText, axis: .vertical)
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
                RoundedRectangle.semiOpaqueWindow()
                    .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(.gray.opacity(0.5), style: StrokeStyle(lineWidth: 1)))
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.gray.opacity(0.5), lineWidth: 1)
                    .fill(.quinary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    ContentView()
}
