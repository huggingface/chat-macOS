//
//  InputViewToolbar.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import SwiftUI

struct InputViewToolbar: View {
    
    @Environment(\.colorScheme) var colorScheme
    var inputText: String
    
    var body: some View {
        HStack {
            Group {
                Menu {
                    Button {
                    } label: {
                        Label("Upload File", systemImage: "rectangle.stack.badge.plus")
                    }
                    Button {
                    } label: {
                        Label("Upload Photo", systemImage: "folder.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                    
                }
                .buttonStyle(.highlightOnHover)
                
                
                ButtonStateAnimation(buttonText: "Search", buttonImage: "globe") {
                    // Activate web search
                }
                
                Button {
                    
                } label: {
                    Image(systemName: "doc.viewfinder")
                }
                .buttonStyle(.highlightOnHover)
                
                Spacer()
                
                Button {
                    
                } label: {
                    Image(systemName: "mic")
                }
                .buttonStyle(.highlightOnHover)
            }
            
            .fontWeight(.semibold)
            .font(.title3)
            
            Button {
                
            } label: {
                Image(systemName: "arrow.up")
                    .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
            }
            .background(
                Circle()
                    .fill(inputText.isEmpty ? Color.gray.opacity(0.5) : (colorScheme == .dark ? Color.white : Color.black))
                .frame(width: 27, height: 27)
            )
            .buttonStyle(.plain)
            .fontWeight(.bold)
            .padding(.leading, 5)
            .font(.title3)
            .disabled(inputText.isEmpty)
        }
        
        .fontDesign(.rounded)
        
        
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDelegate())
        .environment(CoordinatorModel())
}

