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
            if isPipMode {
                Rectangle.semiOpaqueWindow(withStyle: .toolTip)
                Rectangle().fill(.regularMaterial)
            } else {
                Rectangle.semiOpaqueWindow()
                Rectangle().fill(.regularMaterial)
            }
            
        }
    }
    
    var body: some View {
        ZStack {
            backgroundMaterial
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                        if isPipMode {
                            if showPipToolbar {
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
                                .frame(height: 40)
                                .foregroundStyle(.primary)
                                .padding(.horizontal)
                                
                            } else {
                                Rectangle()
                                    .fill(.clear)
                                    .frame(height: 40).zIndex(100)
                                    
                            }
                        }
                    
                    Group {
                        if let _ = coordinator.selectedConversation {
                            if #available(macOS 15.0, *) {
                                List {
                                    ForEach(coordinator.messages) { message in
                                        MessageView(message: message, parentWidth: size.width)
                                            .id(message.id)
                                            .listRowSeparator(.hidden)
                                    }
                                    
                                }
                                .mask {

                                    Rectangle()
                                        .frame(height: size.height - 70)
                                        .offset(y: -40)
                                }
                                .scrollContentBackground(.hidden)
                                .scrollClipDisabled(isPipMode && !showPipToolbar)
                                
                               
                                .onScrollGeometryChange(for: Bool.self) { geometry in
                                    return geometry.contentOffset.y + geometry.bounds.height >=
                                    geometry.contentSize.height - 50 // Added padding
                                } action: { wasGreater, isGreater in
                                    self.showScrollToBottom = !isGreater
                                }
                                .contentMargins(.bottom, 50, for: .scrollContent)
                                .contentMargins(.bottom, 50, for: .scrollIndicators)
//                                .contentMargins(.top, isPipMode ? 50:0, for: .scrollIndicators)
                                
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
                    .overlay {
                        VStack {
                            Spacer()
                            backgroundMaterial
                                .frame(height: 50, alignment: .bottom)
                                .mask(LinearGradient(gradient: Gradient(stops: [
                                    .init(color: .black, location: 0),
                                    .init(color: .black, location: 0.01),
                                    .init(color: .clear, location: 1)
                                ]), startPoint: .bottom, endPoint: .top))
                        }
                            .allowsHitTesting(false)
                    }
                    InputView()
                        .padding([.horizontal, .bottom])
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
                                .offset(y: -40)
                                .buttonStyle(.plain)
                                .transition(.scale(0.8, anchor: .bottom).combined(with: .opacity))
                            }
                        }
                        
                        
                }
            }
        }
        .onGeometryChange(for: CGSize.self) { geometry in
            return geometry.size
        } action: { newValue in
            size = newValue
        }
        .onChange(of: size) { oldValue, newValue in
            size = newValue
        }
        .overlay(content: {
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
//        .ignoresSafeArea(.container)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ContentView()
        .environmentObject(AppDelegate())
        .environment(CoordinatorModel())
}

#Preview {
    ChatView(
        isPipMode: true,
        onPipToggle: { }
    )
        .frame(width: 300, height: 500)
        .environment(CoordinatorModel())
}
