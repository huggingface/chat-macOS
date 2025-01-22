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
                    Text(verbatim: "cyril.zakka@huggingface.co")
                }
                .disabled(true)
                Divider()
                Button {
                } label: {
                    Label("Settings", systemImage: "folder.badge.plus")
                }
                Divider()
                Button {
                } label: {
                    Label("Log out", systemImage: "rectangle.stack.badge.person.crop")
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
            .buttonStyle(.highlightOnPress)
            
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

