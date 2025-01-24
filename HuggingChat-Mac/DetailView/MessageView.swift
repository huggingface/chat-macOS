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
    @State var showReasoning: Bool = false
    var message: MessageViewModel
    var parentWidth: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: message.author == .user ? .trailing : .leading) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                if message.author == .assistant {
                    Image("huggy.fill")
                        .resizable()
                        .fontWeight(.medium)
                        .imageScale(.small)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 10, height: 10)
                        .foregroundStyle(.primary)
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.tertiary, lineWidth: 1)
                                .fill(Color(nsColor: NSColor.controlBackgroundColor))
                                .frame(width: 24, height: 24)
                        }
                    
//                        .offset(y: 5)
                        .padding(.horizontal, 10)
                }
                
                VStack {
                    if message.author == .user  {
                        Text(message.content)
                            .textSelection(.enabled)
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
                        
                        // Reasoning
                        if let reasoning = message.reasoning {
                            Button(action: {
                                showReasoning = true
                            }, label: {
                                HStack {
                                    Text("Thought for 17 seconds")
                                    Image(systemName: "chevron.down")
                                }
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .popover(isPresented: $showReasoning) {
                                    ScrollView {
                                        MarkdownView(text: reasoning).padding()
                                    }
                                    .frame(width: 400, height: 400)
                                        
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                            })
                            .buttonStyle(.plain)
                            
                        }
                        
                        MarkdownView(text: message.content)
                            .markdownRenderingThread(.main)
                            .textSelection(.enabled)
                            .padding(.vertical, 9)
                            .padding(.trailing, 15)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Web sources
                        if let webSources = message.webSources, webSources.count > 0 {
                            SourcesPillView(webSources: webSources)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                   
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: message.author == .user ? .trailing : .leading)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDelegate())
        .environment(CoordinatorModel())
        .frame(height: 400)
}
