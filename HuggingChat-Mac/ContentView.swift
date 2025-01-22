//
//  ContentView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appDelegate: AppDelegate
    
    var body: some View {
        NavigationSplitView(sidebar: {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 200, max: 300)
        }, detail: {
            ChatView(
                isPipMode: false,
                onPipToggle: { [weak appDelegate] in
                    appDelegate?.toggleChatWindow()
                }
            )
            .navigationSplitViewColumnWidth(min: 400, ideal: 400)
        })
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDelegate())
}
