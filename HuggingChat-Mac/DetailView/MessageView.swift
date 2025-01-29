//
//  MessageView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/22/25.
//

import SwiftUI

struct MessageView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @State var showReasoning: Bool = false
    @State var showMessageControls: Bool = false
    
    var message: MessageViewModel
    var isInteractingWithModel: Bool = false
    var parentWidth: CGFloat = 0
    
    var body: some View {
        
        switch message.author {
        case .user, .assistant:
            ZStack(alignment: message.author == .user ? .trailing : .leading) {
                VStack(alignment: message.author == .user ? .trailing : .leading, spacing: 5) {
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
                            if isInteractingWithModel, message.content.isEmpty && !message.isBrowsingWeb && message.reasoning == nil {
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
                                
                                // Reasoning
                                if let reasoning = message.reasoning {
                                    Button(action: {
                                        showReasoning = true
                                    }, label: {
                                        HStack {
                                            Text(message.reasoningUpdates.last != nil ? "\(message.reasoningUpdates.last!)" : "Finished thinking")
                                            Image(systemName: "chevron.down")
                                        }
                                        .shimmering(active: message.content.isEmpty)
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
                                    .markdownRenderingThread(.main)
                                    .markdownRenderingMode(.optimized)
                                    .codeHighlighterTheme(CodeHighlighterTheme(lightModeThemeName: "xcode", darkModeThemeName: "xcode-dark"))

                                
                                
                                    .textSelection(.enabled)
                                
                                //                                .padding(.vertical, 9)
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
                    // Show message controls
                    MessageTools(showMessageControls: showMessageControls, message: message)
                }
                
                
                
            }
            .frame(maxWidth: .infinity, alignment: message.author == .user ? .trailing : .leading)
            .onHover { isHovering in
                showMessageControls = isHovering
            }
        case .system:
            EmptyView()
        }
    }
}

struct MessageTools: View {
    @State private var showCopyFeedback = false
    var showMessageControls: Bool = false
    var message: MessageViewModel
    
    var body: some View {
        HStack {
            // Copy
            Button(action: {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                let copied = pasteboard.setString(message.content, forType: .string)
                
                if copied {
                    withAnimation {
                        showCopyFeedback = true
                    }
                    
                    // Hide feedback after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            showCopyFeedback = false
                        }
                    }
                }
            }, label: {
                Image(systemName: showCopyFeedback ? "checkmark" : "doc.on.doc")
                    .foregroundStyle(.secondary)
            })
            .controlSize(.mini)
            .buttonStyle(.highlightOnHover)
        }
        .opacity(showMessageControls ? 1:0)
        .padding(.leading, message.author == .assistant ? 15:0)
        .padding(.horizontal)
        
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
