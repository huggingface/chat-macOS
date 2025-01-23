//
//  ContentView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject private var appDelegate: AppDelegate
    @Environment(CoordinatorModel.self) private var coordinator
    @AppStorage(UserDefaultsKeys.userLoggedIn) private var isLoggedIn: Bool = false
    
    var body: some View {
        if isLoggedIn {
            mainContent()
        } else {
            LoginView()
                .frame(width: 290, height: 400)
        }
            
    }
    
    @ViewBuilder
    func mainContent() -> some View {
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
        .frame(minHeight: 150)
        .task {
            coordinator.fetchConversations()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDelegate())
        .environment(CoordinatorModel())
}
