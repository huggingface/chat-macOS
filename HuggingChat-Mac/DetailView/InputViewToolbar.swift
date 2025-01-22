//
//  InputViewToolbar.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import SwiftUI

struct InputViewToolbar: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Group {
                Menu {
                    Button {
                    } label: {
                        Label("New Album", systemImage: "rectangle.stack.badge.plus")
                    }
                    Button {
                    } label: {
                        Label("New Folder", systemImage: "folder.badge.plus")
                    }
                    Button {
                    } label: {
                        Label("New Shared Album", systemImage: "rectangle.stack.badge.person.crop")
                    }
                } label: {
                    Image(systemName: "plus")
                    
                }
                
                
                Button {
                    
                } label: {
                    Image(systemName: "globe")
                }
                
                Button {
                    
                } label: {
                    Image(systemName: "doc.viewfinder")
                }
                
                Spacer()
                
                Button {
                    
                } label: {
                    Image(systemName: "mic")
                }
            }
            .buttonStyle(.highlight)
            .fontWeight(.semibold)
            .font(.title3)
            
            Button {
                
            } label: {
                Image(systemName: "arrow.up")
                    .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
            }
            .background(
                Circle()
                    .fill(colorScheme == .dark ? Color.white : Color.black)
                .frame(width: 27, height: 27)
            )
            .buttonStyle(.plain)
            .fontWeight(.bold)
            .padding(.leading, 5)
            .font(.title3)
        }
        
        .fontDesign(.rounded)
        
        
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDelegate())
}
