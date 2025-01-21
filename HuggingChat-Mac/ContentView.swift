//
//  ContentView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import SwiftUI

struct ContentView: View {
    
    
    
    var body: some View {
        NavigationSplitView(sidebar: {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 200, max: 300)
        }, detail: {
            ChatView()
                .navigationSplitViewColumnWidth(min: 300, ideal: 300)
        })
        
        
    }
}

#Preview {
    ContentView()
}
