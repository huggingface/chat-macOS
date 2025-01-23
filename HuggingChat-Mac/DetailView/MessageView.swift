//
//  MessageView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/22/25.
//

import SwiftUI
import MarkdownView

struct MessageView: View {
    
    @Environment(\.colorScheme) var colorScheme
    var message: Message
    var parentWidth: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: message.author == .user ? .trailing : .leading) {
            HStack(alignment: .firstTextBaseline) {
                if message.author == .assistant {
                    Image("")
                        .resizable()
                        .fontWeight(.medium)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15, height: 15)
                        .foregroundStyle(.primary)
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.tertiary, lineWidth: 1)
                                .fill(Color(nsColor: NSColor.controlBackgroundColor))
                                .frame(width: 24, height: 24)
                        }
                    
                        .offset(y: 5)
                        .padding(.horizontal, 10)
                }
                
                VStack {
                    if message.author == .user  {
                        Text(message.content)
                            .padding(.vertical, 9)
                            .padding(.horizontal, 15)
                            .background {
                                if message.author == .user {
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color(.gray).quinary)
                                }
                            }
                            .frame(maxWidth:  message.author == .user ? parentWidth * 0.75 : .infinity, alignment: message.author == .user ? .trailing : .leading)
                            .padding(message.author == .user ? .trailing:.leading, message.author == .user ? 10 : 0)
                    } else if message.author == .assistant {
                        MarkdownView(text: message.content)
                            .markdownRenderingThread(.background)
                            .padding(.vertical, 9)
                            .padding(.trailing, 15)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: message.author == .user ? .trailing : .leading)
        .padding(.horizontal)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDelegate())
        .environment(CoordinatorModel())
        .frame(height: 400)
}
