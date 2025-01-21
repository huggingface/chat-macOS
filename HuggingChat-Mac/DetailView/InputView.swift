//
//  InputView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import SwiftUI

struct InputView: View {
    
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
            RoundedRectangle(cornerRadius: 14)
                .stroke(.separator, lineWidth: 0.5)
                .fill(.quinary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    ContentView()
}
