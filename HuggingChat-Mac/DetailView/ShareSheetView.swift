//
//  ShareSheetView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/24/25.
//

import SwiftUI

struct ShareSheetView: View {
    
    @Environment(CoordinatorModel.self) private var coordinator
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            // Toolbar
            HStack(alignment: .center) {
                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "xmark")
                })
                .frame(width: 45, height: 45)
                .buttonStyle(.highlightOnHover)
                .opacity(0)
                
                Text("Share link to chat")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .center)
                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "xmark")
                })
                .frame(width: 45, height: 45)
                .buttonStyle(.highlightOnHover)
            }
            .background(.ultraThickMaterial)

            Text("Any messages sent or received after sharing this link will not be visible to your recipients.")
                .multilineTextAlignment(.leading)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 5)
            
            // Chat Preview
            VStack(spacing: 0) {
                ChatView(
                    isPipMode: false,
                    isPreviewMode: true,
                    onPipToggle: { },
                    showShareSheet: .constant(false)
                )
                
                if let selectedConversationId = coordinator.selectedConversation, let conversation = coordinator.conversations.first(where: { $0.id == selectedConversationId }) {
                    VStack(spacing: 5) {
                        Text(conversation.title.withoutEmoji())
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(conversation.updatedAt, format: .dateTime.day().month().year())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(.windowBackground)
                } else {
                    VStack(spacing: 5) {
                        Text("Conversation Title")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(Date.now, format: .dateTime.day().month().year())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(.windowBackground)
                }
                
                
            }
            .background(.windowBackground)
            .frame(height: 400)
            
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .padding(.horizontal)
            
//            .background(Color(.windowBackgroundColor))
            
            
            
            // Share button
            ShareLink(item: coordinator.sharedConversationLink ?? URL(string: "https://huggingface.co/chat/")!) {
                Label("Share link", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .frame(height: 25)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
            
            .buttonStyle(.highlightOnPress(defaultBackground: .blue))
            .frame(maxWidth: .infinity)
            
            .contentShape(.rect)
            .padding()
            
        }
        
            
    }
}

#Preview {
    ShareSheetView()
        .environmentObject(AppDelegate())
        .environment(CoordinatorModel())
}
