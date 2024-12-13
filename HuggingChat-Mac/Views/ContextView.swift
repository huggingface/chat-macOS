//
//  ContextView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 12/4/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContextView: View {
    
    @Environment(ConversationViewModel.self) private var conversationModel
    @Binding var showingContext: Bool
    
    var body: some View {
        HStack(alignment: .center) {
            Image(nsImage: conversationModel.contextAppIcon ??
                  NSWorkspace.shared.icon(for: UTType.application))
            .resizable()
            .aspectRatio(1, contentMode: .fit)
            .frame(width: 16)
            VStack {
                if conversationModel.contextIsSupported {
                    Text("Working with \(conversationModel.contextAppName ?? "")")
                        .fontWeight(.semibold)
                } else {
                    Text("\(conversationModel.contextAppName ?? "") is not currently supported.")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: {
                conversationModel.clearContext()
                withAnimation(.smooth(duration: 0.3)) {
                    showingContext = false
                }
                
            }, label: {
                Label("", systemImage: "xmark.circle.fill")
                    .labelStyle(.iconOnly)
            })
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 7)
        .padding(.horizontal, 7)
            .background(
                UnevenRoundedRectangle(cornerRadii: .init(
                topLeading: 9,
                bottomLeading: 0,
                bottomTrailing: 0,
                topTrailing: 9),
                style: .continuous)
                .fill(.gray.opacity(0.3))
            )
    }
}

#Preview("dark") {
    ChatView()
        .frame(height: 300)
        .environment(ModelManager())
        .environment(ConversationViewModel())
        .environment(AudioModelManager())
        .colorScheme(.dark)
}
