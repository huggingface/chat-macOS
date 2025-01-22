//
//  ChatView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import SwiftUI

struct ChatView: View {
    
    var isPipMode: Bool = true
    var onPipToggle: () -> Void
    @EnvironmentObject private var appDelegate: AppDelegate
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingPopover = false
    @State private var showPipToolbar: Bool = false
    
    private var backgroundMaterial: some View {
            ZStack {
//                if !isPipMode {
                    Rectangle.semiOpaqueWindow()
//                }
                Rectangle().fill(.regularMaterial)
            }
        }
    
    var body: some View {
        ZStack {
            backgroundMaterial

            ScrollView(.vertical) {
#if DEBUG
                LazyVStack {
                    ForEach(1...100, id: \.self) { value in
                        Text("Row \(value)")
                    }
                }
#endif
            }
            .contentMargins(.bottom, -20, for: .scrollContent)
            .contentMargins(.top, 20, for: .scrollContent)
            .overlay {
                VStack {
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
                        
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .background {
                            backgroundMaterial
                        }
                        
                        Spacer()
                            .allowsHitTesting(false)
                        
                    }
                }
                
                
            }
            .safeAreaInset(edge: .bottom, content: {
                InputView()
                    .padding([.horizontal, .bottom])
                    .padding(.top, 50)
                    
                    .background {
                        backgroundMaterial
                            .mask(LinearGradient(gradient: Gradient(stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: 0.7),
                                .init(color: .clear, location: 1)
                            ]), startPoint: .bottom, endPoint: .top))
                            
                    }
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
        .environmentObject(AppDelegate())
}
