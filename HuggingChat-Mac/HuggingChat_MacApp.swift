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
    
    @State var coordinatorModel = CoordinatorModel()
    @State var hfChatSession = HuggingChatSession()
    @State var modelDownloader = ModelDownloader()
    
    @Environment(\.openWindow) private var openWindow
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("userLoggedIn") private var userLoggedIn: Bool = false
    @AppStorage("onboardingDone") private var onboardingDone: Bool = false
    @AppStorage("appearance") private var appearance: Appearance = .auto
    
    private let updaterController: SPUStandardUpdaterController
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    var body: some Scene {

        // Intro view
        Window("Login", id: "login", content: {
            // TODO: Fix this
            if !userLoggedIn || !onboardingDone {
            OnboardingView()
                    .frame(width: 300, height: 400)
//                    .toolbar(removing: .title)
                    .toolbarBackground(.hidden, for: .windowToolbar)
//                    .windowFullScreenBehavior(.disabled)
                    .environment(coordinatorModel)
                    .preferredColorScheme(colorScheme(for: appearance))
                    .onOpenURL { url in
                        if let component = URLComponents(string: url.absoluteString),
                           let code = component.queryItems?.first(where: { $0.name == "code"})?.value,
                           let state = component.queryItems?.first(where: { $0.name == "state"})?.value {
                            coordinatorModel.validateSignup(code: code, state: state)
                        }
                    }
            }
        })
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        
        // About
        Window("About", id: "about", content: {
            AboutView()
                .frame(width: 450, height: 175)
//                .toolbar(removing: .title)
                .toolbarBackground(.hidden, for: .windowToolbar)
//                .containerBackground(.thickMaterial, for: .window)
//                .windowMinimizeBehavior(.disabled)
                .preferredColorScheme(colorScheme(for: appearance))
        })
        .windowResizability(.contentSize)
//        .restorationBehavior(.disabled)
        
        // Settings
        Settings {
            SettingsView()
                .environment(hfChatSession)
                .environment(appDelegate.themeEngine)
                .environment(appDelegate.conversationModel)
                .environment(appDelegate.modelManager)
                .environment(modelDownloader)
                .environment(appDelegate.audioModelManager)
                .preferredColorScheme(colorScheme(for: appearance))
            
        }
        .windowResizability(.contentSize)
//        .restorationBehavior(.disabled)
        
        // Command Bar
        .commands {
            CommandGroup(after: .appSettings) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
            
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button(action: {
                    for window in NSApplication.shared.windows {
                        if window.identifier?.rawValue == "about" {
                            window.makeKeyAndOrderFront(nil)
                            return
                        }
                        
                    }
                    openWindow(id: "about")
                    
                }) {
                    Text("About \(Bundle.main.appName)")
                }
            }
            
            CommandGroup(replacing: .help) {
                Button(action: {
                    openWindow(id: "login")
                }) {
                    Text("Open Login")
                }
            }
        }
    }
    
    private func colorScheme(for appearance: Appearance) -> ColorScheme? {
        switch appearance {
        case .light:
            return .light
        case .dark:
            return .dark
        case .auto:
            return nil
        }
    }
}
