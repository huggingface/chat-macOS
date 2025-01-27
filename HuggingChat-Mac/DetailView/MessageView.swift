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
                        .padding(.leading, 20)
                        .padding(.trailing, 5)
                    
                    // Loading animation
                    if message.content.isEmpty && message.isBrowsingWeb == false {
                        LoadingAnimatedCircleView()
                    }
                    
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
                        
                        if message.isBrowsingWeb {
                            Text(message.webSearchUpdates.last ?? "Searching the web")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .shimmering()
                        }
                        
//                        if isThinking {
//                            Text("Thinking")
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                                .shimmering()
//                        }
                        
                        // Reasoning
                        if let reasoning = message.reasoning {
                            Button(action: {
                                showReasoning = true
                            }, label: {
                                HStack {
                                    Text(message.reasoningUpdates.last != nil ? "Thinking \(message.reasoningUpdates.last!.lowercased())" : "Finished thinking")
                                    Image(systemName: "chevron.down")
                                }
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .popover(isPresented: $showReasoning) {
                                    ScrollView {
                                        MarkdownView(text: reasoning)
                                            .padding(.horizontal, 30)
                                    }
                                    .frame(width: 400, height: 400)
                                    .contentMargins(.vertical, 40, for: .scrollContent)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                            })
                            .buttonStyle(.plain)
                            
                        }
                        
                        MarkdownView(text: message.content)
                            .markdownViewRole(.normal)
                            .markdownRenderingThread(.main)
                            .markdownRenderingMode(.optimized)
                            
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

struct LoadingAnimatedCircleView: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(Color.primary)
            .opacity(isAnimating ? 0.8 : 1)
            .frame(width: 13, height: 13)
            .scaleEffect(isAnimating ? 0.7 : 1, anchor: .center)
            .animation(
                .easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDelegate())
        .environment(CoordinatorModel())
        .frame(height: 400)
}
