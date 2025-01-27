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
    var onSubmit: (() -> Void)
    
    @Environment(CoordinatorModel.self) private var coordinator
    @Environment(\.colorScheme) var colorScheme
    @State private var inputText: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField("", text: $inputText, prompt: Text("Message \(conversationModelName())").foregroundColor(.primary), axis: .vertical)
                .font(.system(size: 14.5, weight: .regular, design: .default))
                .textFieldStyle(.plain)
                .lineLimit(12)
                .frame(maxHeight: .infinity, alignment: .top)
                .onSubmit {
                    coordinator.send(text: inputText)
                    onSubmit()
                }
            InputViewToolbar(inputText: inputText) {
                DispatchQueue.main.async {
                    coordinator.send(text: inputText)
                    onSubmit()
                }
            }
                
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .frame(minHeight: 87)
        
        .background {
            if isChatBarMode {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThickMaterial)
                    .fill(colorScheme == .dark ? .black.opacity(0.4) : .white.opacity(0.4))
                    .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(.gray.opacity(0.5), style: StrokeStyle(lineWidth: 0.5)))
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.gray.opacity(0.5), lineWidth: 1)
                    .fill(.regularMaterial)
                    .fill(.quinary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    func conversationModelName() -> String {
        if let selectedConversationId = coordinator.selectedConversation, let conversation = coordinator.conversations.first(where: { $0.id == selectedConversationId }) {
            return conversation.modelId
        } else {
            let modelName = coordinator.activeModel?.displayName.split(separator: "/").last ?? ""
            let primaryName = modelName.split(separator: "-").first ?? ""
            let secondaryName = modelName.components(separatedBy: primaryName).last?.trimmingCharacters(in: .whitespaces) ?? ""
            return secondaryName
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDelegate())
        .environment(CoordinatorModel())
}

