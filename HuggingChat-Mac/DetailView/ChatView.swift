//
//  ChatView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import SwiftUI

struct ChatView: View {
    
    var isPipMode: Bool = false
    var onPipToggle: () -> Void
    @EnvironmentObject private var appDelegate: AppDelegate
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingPopover = false
    @State private var showPipToolbar: Bool = false
    
    var body: some View {
        ZStack {
            if !isPipMode {
                Rectangle.semiOpaqueWindow()
            }
            Rectangle().fill(.regularMaterial)
            
                
                
                    
                    ScrollView(.vertical) {
                        
                    }
                    .safeAreaInset(edge: .top, content: {
                        if isPipMode && showPipToolbar {
                            HStack {
                                Button(action: {
                                    onPipToggle()
                                }, label: {
                                    Image(systemName: "xmark.circle.fill")
                                })
                                .buttonStyle(.plain)
                                
                                Spacer()
          
                                Button(action: {
                                    // Exit pip mode
                                }, label: {
                                    Image(systemName: "pip.exit")
                                })
                                .buttonStyle(.accessoryBar)
                                
                                
                                Button(action: {
                                    // new conversation
                                }, label: {
                                    Image(systemName: "square.and.pencil")
                                })
                                .buttonStyle(.accessoryBar)
                                
                            }
                            
                            .padding(.horizontal, 7)
                            .padding(.top, 7)
//                            .background(.regularMaterial)
                        }
                    })
                    .safeAreaInset(edge: .bottom, content: {
                        InputView()
                            .padding([.horizontal, .bottom])
                    })
                    .toolbar {
                        ToolbarItemGroup(placement: .navigation) {
                            Button(action: {
                                showingPopover = true
                            }, label: {
                                HStack(spacing: 5) {
                                    Text("DeepSeek-R1")
                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                        .fontWeight(.medium)
                                        .font(.title3)
                                    Image(systemName: "chevron.right")
                                        .imageScale(.small)
                                }
                            })
                            .buttonStyle(.accessoryBar)
                            .popover(isPresented: $showingPopover, arrowEdge: .bottom) {
                                Text("Your content here")
                                    .font(.headline)
                                    .padding()
                            }
                            
                        }
                        
                        ToolbarItemGroup(placement: .primaryAction) {
                            Button(action: {
                                // Share conversation
                            }, label: {
                                Image(systemName: "square.and.arrow.up")
                            })
                            Button(action: {
                                onPipToggle()
                            }, label: {
                                Image(systemName: "pip")
                            })
                        }
                    }
                
            
        }
        .onHover { over in
            showPipToolbar = over
        }
        .overlay(content: {
            if isPipMode {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.gray.opacity(0.5), lineWidth: 1.0)
            }
        })
        .clipShape(RoundedRectangle(cornerRadius: isPipMode ? 22:0, style: .continuous))
        
        
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ChatView(isPipMode: true) {
        
    }
}
