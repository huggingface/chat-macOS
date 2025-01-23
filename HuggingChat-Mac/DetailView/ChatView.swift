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
    @Environment(CoordinatorModel.self) private var coordinator
    @Environment(\.colorScheme) var colorScheme
    
    // Toolbar
    @State private var showingPopover = false
    @State private var showPipToolbar: Bool = false
    
    // Scrollview animation
    @State var scrollViewHeight: CGFloat = 0
    @State var anchorToBottom: Bool = false
    @State var showScrollToBottom: Bool = false
    @State var contentHeight : CGFloat = 0
    @State var size: CGSize = .zero
    
    private var backgroundMaterial: some View {
        ZStack {
            Rectangle.semiOpaqueWindow()
            Rectangle().fill(.regularMaterial)
        }
    }
    
    var body: some View {
        ZStack {
            backgroundMaterial.onGeometryChange(for: CGSize.self) { geometry in
                return geometry.size
            } action: { newValue in
                size = newValue
            }
            ScrollViewReader { proxy in
                Group {
                    if let _ = coordinator.selectedConversation {
                        
                        if #available(macOS 15.0, *) {
                            ScrollView {
                                LazyVStack {
                                    ForEach(coordinator.messages) { message in
                                        MessageView(message: message, parentWidth: size.width)
                                            .listRowSeparator(.hidden)
                                            .id(message.id)
                                    }
                                }
                            }
                            
//                            .defaultScrollAnchor(.bottom) // Fix this
                            .contentMargins(.bottom, -20, for: .scrollContent)
                            .contentMargins(.top, 20, for: .scrollContent)
                            .onScrollGeometryChange(for: Bool.self) { geometry in
                                return geometry.contentOffset.y + geometry.bounds.height >=
                                geometry.contentSize.height - geometry.contentInsets.bottom
                            } action: { wasGreater, isGreater in
                                self.showScrollToBottom = !isGreater
                            }
                            
                        } else {
                            List {
                                //                                ForEach(conversation.messages) { message in
                                //                                    MessageView(message: message)
                                //                                }
                            }
                        }
                        
                    } else {
                        makeNoContentView()
                    }
                }
                .safeAreaInset(edge: .bottom, content: {
                    if #available(macOS 15.0, *) {
                        InputView()
                            .padding([.horizontal, .bottom])
                            .padding(.top, 50)
                            .overlay(alignment: .top) {
                                if showScrollToBottom {
                                    Button(action: {
                                        withAnimation(.easeOut) {
                                            proxy.scrollTo(coordinator.messages.last?.id, anchor: .bottom)
                                        }
                                    }, label: {
                                        Image(systemName: "arrow.down")
                                            .fontWeight(.bold)
                                            .imageScale(.small)
                                            .foregroundStyle(colorScheme == .dark ? .white:.black)
                                            .padding(5)
                                            .background {
                                                Circle()
                                                    .fill(colorScheme == .dark ? Color(.windowBackgroundColor):.white)
                                                    .frame(width: 30, height: 30)
                                                    .shadow(radius: 2)
                                            }
                                        
                                    })
                                    .frame(width: 30, height: 30)
                                    .buttonStyle(.plain)
                                    .transition(.scale(0.8, anchor: .bottom).combined(with: .opacity))
                                }
                            }
                            .background {
                                backgroundMaterial
                                    .mask(LinearGradient(gradient: Gradient(stops: [
                                        .init(color: .black, location: 0),
                                        .init(color: .black, location: 0.7),
                                        .init(color: .clear, location: 1)
                                    ]), startPoint: .bottom, endPoint: .top))
                                
                            }
                    } else {
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
                    }
                    
                    
                })
            }
        }
        .overlay(content: {
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
            if isPipMode {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.gray.opacity(0.5), lineWidth: 1.0)
            }
        })
        .clipShape(RoundedRectangle(cornerRadius: isPipMode ? 22:0, style: .continuous))
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
        .onHover { over in
            showPipToolbar = over
        }
    }
    
    @ViewBuilder
    func makeNoContentView() -> some View {
        ZStack {
            Image("huggy")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .symbolRenderingMode(.none)
                .foregroundStyle(.tertiary)
                .frame(width: 55, height: 55)
            
        }
        .frame(maxHeight: .infinity, alignment: .center)
        .ignoresSafeArea(.container)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ContentView()
        .environmentObject(AppDelegate())
        .environment(CoordinatorModel())
}
