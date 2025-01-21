//
//  ChatView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import SwiftUI

extension View {
    public static func semiOpaqueWindow() -> some View {
        VisualEffect().ignoresSafeArea()
    }
}

struct VisualEffect : NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSVisualEffectView()
        view.material = .headerView
        view.blendingMode = .behindWindow
        view.state = .active
        
        view.isEmphasized = true
        return view
    }
    func updateNSView(_ view: NSView, context: Context) { }
}

struct ChatView: View {
    
    
    @Environment(\.colorScheme) var colorScheme
    @State private var showingPopover = false
    var body: some View {
        ZStack {
            ZStack {
                Rectangle.semiOpaqueWindow()
                Rectangle().fill(.regularMaterial)
            }
            ScrollView(.vertical) {
                
            }
            .safeAreaInset(edge: .bottom, content: {
                InputView()
                    .padding([.horizontal, .bottom])
            })
        }
        
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: {
                    showingPopover = true
                }, label: {
                    HStack(spacing: 5) {
                        Text("ChatGPT")
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
                    // PiP
                }, label: {
                    Image(systemName: "pip")
                })
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ContentView()
}
