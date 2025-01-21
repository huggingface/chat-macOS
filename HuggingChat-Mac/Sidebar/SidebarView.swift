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
        List {
            Section("Chats", content: {
                LazyHStack {
                   
                }
            })
           
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
}

