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
    
    // Toolbar
    @State private var showingPopover = false
    @State private var showPipToolbar: Bool = false
    
    // Scrollview animation
    @State var scrollViewHeight: CGFloat = 0
    @State var anchorToBottom: Bool = false
    @State var showScrollToBottom: Bool = false
    @State var contentHeight : CGFloat = 0
    
    private var backgroundMaterial: some View {
        ZStack {
            Rectangle.semiOpaqueWindow()
            Rectangle().fill(.regularMaterial)
        }
    }
    
    var body: some View {
        ZStack {
            backgroundMaterial
            Group {
                
                    ScrollViewReader { value in
                        if #available(macOS 15.0, *) {
                        ScrollView(.vertical) {
#if DEBUG
                            LazyVStack {
//                                ForEach(1...70, id: \.self) { value in
//                                    Text("Row \(value)")
//                                        .id(value)
//                                        .frame(height: 50)
//                                }
                            }
#endif
                        }
                        .defaultScrollAnchor(anchorToBottom ? .bottom : .top)
                        .contentMargins(.bottom, -20, for: .scrollContent)
//                        .contentMargins(.top, 20, for: .scrollContent)
//                        // Anchor to bottom when content view becomes greater than scroll view height
//                        .onScrollGeometryChange(for: Bool.self) { geometry in
//                            return geometry.contentSize.height > geometry.bounds.height
//                        } action: { wasGreater, isGreater in
//                            self.anchorToBottom = isGreater
//                        }
                        .onScrollGeometryChange(for: Bool.self) { geometry in
                            return geometry.contentOffset.y + geometry.bounds.height >=
                                   geometry.contentSize.height - geometry.contentInsets.bottom
                        } action: { wasGreater, isGreater in
                            self.showScrollToBottom = !isGreater
                        }
                        
                    } else {
                        ScrollView(.vertical) {
#if DEBUG
                            LazyVStack {
                                ForEach(1...100, id: \.self) { value in
                                    Text("Row \(value)")
                                }
                            }
#endif
                        }
//                        .contentMargins(.bottom, -20, for: .scrollContent)
//                        .contentMargins(.top, 20, for: .scrollContent)
                    }
                }
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
                        if #available(macOS 15.0, *) {
                            InputView()
                                .padding([.horizontal, .bottom])
                                .padding(.top, 50)
                                .overlay(alignment: .top) {
                                    if showScrollToBottom {
                                        Button(action: {
//                                            scrollToBottom(proxy: value)
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
//                                        .offset(y: -40)
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
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
//        if let lastMessage = userModel.conversation.last {
//            withAnimation(.linear, {
//                proxy.scrollTo(lastMessage.id, anchor: .bottom)
//            })
//            
//        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ContentView()
        .environmentObject(AppDelegate())
}


struct AdaptiveScrollView<Content: View>: View {
    let content: Content
    
    @State private var scrollViewHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var anchorToBottom: Bool = false
    @State private var showScrollToBottom: Bool = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                content
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: ContentHeightPreferenceKey.self,
                                value: geo.size.height
                            )
                        }
                    )
            }
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ScrollViewHeightPreferenceKey.self,
                        value: geo.size.height
                    )
                }
            )
            .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
                contentHeight = height
                updateScrollAnchor()
            }
            .onPreferenceChange(ScrollViewHeightPreferenceKey.self) { height in
                scrollViewHeight = height
                updateScrollAnchor()
            }
            .defaultScrollAnchor(anchorToBottom ? .bottom : .top)
            .onChange(of: anchorToBottom) { oldValue, newValue in
                withAnimation(.smooth) {
                    if newValue {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private func updateScrollAnchor() {
        // Add a buffer (e.g., 100 points) to prevent premature anchoring
        let buffer: CGFloat = 100
        withAnimation(.smooth) {
            anchorToBottom = contentHeight > scrollViewHeight + buffer
        }
    }
}

// Preference Keys for geometry reading
private struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct ScrollViewHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
