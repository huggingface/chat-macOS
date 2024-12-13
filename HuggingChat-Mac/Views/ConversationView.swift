//
//  ConversationView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 12/13/24.
//

import SwiftUI

struct ConversationView: View {
    
    @Environment(ConversationViewModel.self) private var conversationModel
    @Environment(ModelManager.self) private var modelManager
    
    @AppStorage("inlineCodeHiglight") private var inlineCodeHiglight: AccentColorOption = .blue
    @AppStorage("lightCodeBlockTheme") private var lightCodeBlockTheme: String = "xcode"
    @AppStorage("darkCodeBlockTheme") private var darkCodeBlockTheme: String = "monokai-sublime"
    
    @Binding var isResponseVisible: Bool
    @Binding var responseSize: CGSize
    
    var isLocal: Bool = false
    
    var body: some View {
        ZStack {
            if !isLocal {
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 15) {
                            ForEach(conversationModel.messages) { message in
                                MessageView(message: message)
                            }
                        }
                    }
                }
            }
        }
            .frame(height: 300)
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .contentMargins(.vertical, 20, for: .scrollContent)
            .scrollIndicators(.hidden)
            .background(.ultraThickMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.secondary.opacity(0.5), lineWidth: 1.0)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    ConversationView(isResponseVisible: .constant(true), responseSize: .constant(CGSize(width: 300, height: 500)))
        .environment(ModelManager())
        .environment(ConversationViewModel())
}
