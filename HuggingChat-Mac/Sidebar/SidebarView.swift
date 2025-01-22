//
//  SidebarView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import SwiftUI

struct SidebarView: View {
    
    @State private var searchChat: String = ""
    
    var body: some View {
        VStack {
            List {
                Section("Chats", content: {
                    LazyHStack {
                        
                    }
                })
                
            }
            
            // Profile Pic
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
                HStack {
                    ZStack {
                        Circle()
                            .foregroundStyle(.quinary)
                            .frame(width: 28, height: 28)
                        Text("🤗")
                    }
                    Text("Cyril Zakka")
                        
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.simpleHighlight)
            
            .frame(height: 60)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .buttonStyle(.plain)
        }
        .searchable(text: $searchChat, placement: .sidebar)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: {}, label: {
                    Image(systemName: "square.and.pencil")
                })
                
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDelegate())
}

