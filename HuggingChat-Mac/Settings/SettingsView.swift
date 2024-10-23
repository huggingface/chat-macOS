//
//  SettingsView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/17/24.
//

import SwiftUI

struct SettingsListViewIcon: View {
    
    var iconName: String
    var systemImage: String
    var tint: Color
    
    var body: some View {
        Label(title: {
            Text(iconName)
        }, icon: {
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(RoundedRectangle(cornerRadius: 5).fill(tint.gradient))
            
        })
    }
}


struct SettingsView: View {
    
    @Environment(ModelManager.self) private var modelManager
    @Environment(ModelDownloader.self) private var modelDownloader
    @Environment(AudioModelManager.self) private var audioModelManager
    @Environment(ConversationViewModel.self) private var conversationManager
    
    @AppStorage("hideDock") private var hideDock: Bool = false
    
    @State private var columnVisibility = NavigationSplitViewVisibility.detailOnly
    @State private var selectedSidebarItem: String? = "General"
    @State private var searchText = ""
    private let allSettings = ["General", "Appearance", "Components"]
    
    private var filteredSettings: [String] {
        if searchText.isEmpty {
            return allSettings
        } else {
            return allSettings.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        
        if #available(macOS 15.0, *) {
            TabView {
                Tab("General", systemImage: "gearshape") {
                    GeneralSettingsView()
                        .environment(modelManager)
                        .environment(conversationManager)
                }
                
                //            Tab("Dictation", systemImage: "waveform.badge.mic") {
                //                DictationSettings()
                //                    .environment(audioModelManager)
                //            }
                
                Tab("Appearance", systemImage: "paintbrush") {
                    AppearanceSettings()
                        .environment(modelManager)
                        .environment(modelDownloader)
                }
                
//                Tab("Advanced", systemImage: "wrench.and.screwdriver") {
//                    AdvancedSettings()
//                }
                
                Tab("Components", systemImage: "square.3.layers.3d") {
                    ComponentsSettingsView()
                        .environment(modelManager)
                        .environment(modelDownloader)
                }
            }
            .frame(maxWidth: 500, maxHeight: .infinity)
            .onAppear {
                // Show dock icon when settings view is shown
                NSApp.setActivationPolicy(.regular)
            }
            .onDisappear {
                // For better UX experience, trigger hide dock after exiting Settings
                if hideDock {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        } else {
            TabView {
                GeneralSettingsView()
                    .environment(modelManager)
                    .tabItem {
                        Label("General", systemImage: "gearshape")
                    }
                //                DictationSettings()
                //                    .environment(audioModelManager)
                //                        .tabItem {
                //                            Label("Dictation", systemImage: "waveform.badge.mic")
                //                        }
                
                AppearanceSettings()
                    .environment(modelManager)
                    .environment(modelDownloader)
                    .tabItem {
                        Label("Appearance", systemImage: "paintbrush")
                    }
                
                ComponentsSettingsView()
                    .environment(modelManager)
                    .environment(modelDownloader)
                    .tabItem {
                        Label("Components", systemImage: "square.3.layers.3d")
                    }
            }
        }
        
    }
    
}

#Preview {
    SettingsView()
        .environment(ModelManager())
        .environment(ModelDownloader())
        .environment(AudioModelManager())
        .environment(ConversationViewModel())
}
