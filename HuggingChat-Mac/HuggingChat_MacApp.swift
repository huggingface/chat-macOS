//
//  HuggingChat_MacApp.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/16/24.
//

import SwiftUI
import Combine
import Sparkle


@main
struct HuggingChat_MacApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    private let updaterController: SPUStandardUpdaterController
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            appDelegate.makeContentView()
                .navigationTitle("") // Hide tab bar app title
                .frame(minHeight: 150)
        }
        .windowToolbarStyle(.unified)
        .defaultSize(width: 600, height: 400)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDelegate())
}
