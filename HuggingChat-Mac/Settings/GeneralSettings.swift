//
//  GeneralSettings.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/22/24.
//

import SwiftUI
import LaunchAtLogin
import KeyboardShortcuts
import Combine

struct GeneralSettingsView: View {
    
    @Environment(\.openWindow) private var openWindow
    @Environment(ModelManager.self) private var modelManager
    @Environment(ConversationViewModel.self) private var conversationManager
    
    @State var externalModels: [LLMModel] = []
    @State var cancellables = [AnyCancellable]()
    
    @AppStorage("userLoggedIn") private var userLoggedIn: Bool = false
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("hideDock") private var hideDock: Bool = false
    @AppStorage("localModel") private var selectedLocalModel: String = "None"
    @AppStorage("externalModel") private var selectedExternalModel: String = "meta-llama/Meta-Llama-3.1-70B-Instruct"
    @AppStorage("useWebSearch") private var useWebSearch = false
    @AppStorage("chatClearInterval") private var chatClearInterval: String = "never"
    @AppStorage("isLocalGeneration") private var isLocalGeneration: Bool = false
    
    var body: some View {
        Form {
            Section("Account", content: {
                HStack {
                    if let currentUser = HuggingChatSession.shared.currentUser {
                        AsyncImage(url: currentUser.avatarUrl) { phase in
                            switch phase {
                            case .failure:
                                ZStack {
                                    Circle()
                                        .fill(.quinary)
                                        .frame(height: 40)
                                    Text("🤗")
                                }
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 40)
                                    .clipShape(Circle())
                                
                            default:
                                ZStack {
                                    Circle()
                                        .fill(.quinary)
                                        .frame(height: 40)
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                
                            }
                        }
                    } else {
                        ZStack {
                            Circle()
                                .fill(.quaternary)
                                .frame(height: 40)
                            Text("🤗")
                        }
                    }
                    
                    if !userLoggedIn && HuggingChatSession.shared.currentUser == nil {
                        // Not logged in
                        VStack(alignment: .leading) {
                            Text("Sign in")
                                .font(.headline)
                            Text("with your HuggingFace account")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            
                        }
                        Spacer()
                        Button("Sign in", action: {
                            userLoggedIn =  false
                            openWindow(id: "login")
                        })
                    } else {
                        if let currentUser = HuggingChatSession.shared.currentUser {
                            VStack(alignment: .leading) {
                                Text("Hi, \(currentUser.username)")
                                    .font(.headline)
                                if currentUser.email != "" {
                                    Text(HuggingChatSession.shared.currentUser?.email ?? "userID")
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                }
                            }
                            Spacer()
                            Button("Sign out", action: {
                                HuggingChatSession.shared.logout()
                                userLoggedIn =  false
                            })
                        }
                    }
                }
            })
            Section(content: {
//                LabeledContent("CoreML Model:", content: {
//                    HStack {
//                        Picker("", selection: $selectedLocalModel) {
//                            Text("None").tag("None")
//                            ForEach(modelManager.availableModels, id: \.id) { option in
//                                Text(option.name).tag(option.name)
//                            }
//                        }
//                        // Local model status
//                        StatusIndicatorView(status: modelManager.status)
//                        
//                    }
//                    .labelsHidden()
//                    .onChange(of: selectedLocalModel) {
//                        if selectedLocalModel == "None" {
//                            modelManager.cancelLoading()
//                        } else if let selectedLocalModel = modelManager.availableModels.first(where: { $0.name == selectedLocalModel }) {
//                            modelManager.localModelDidChange(to: selectedLocalModel)
//                        }
//                    }
//                })
                
                LabeledContent("GGUF Model:", content: {
                    HStack {
                        Picker("", selection: $selectedLocalModel) {
                            Text("None").tag("None")
                            ForEach(modelManager.availableModels, id: \.id) { option in
                                Text(option.name).tag(option.name)
                            }
                        }
                        // Local model status
                        StatusIndicatorView(status: modelManager.status)
                        
                    }
                    .labelsHidden()
                    .onChange(of: selectedLocalModel) {
                        if selectedLocalModel == "None" {
                            isLocalGeneration = false
                            modelManager.cancelLoading()
                        } else if let selectedLocalModel = modelManager.availableModels.first(where: { $0.name == selectedLocalModel }) {
                            modelManager.localModelDidChange(to: selectedLocalModel)
                        }
                    }
                })
                
            }, header: {
                Text("Local Models")
            }, footer: {
                Text("Local models will run queries entirely on your local machine.")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .foregroundColor(.secondary)
            })
            
            Section(content: {
                LabeledContent("HuggingFace:", content: {
                    Picker("", selection: $selectedExternalModel) {
                        ForEach(externalModels, id: \.id) { option in
                            let components = option.name.split(separator: "/", maxSplits: 1)
                            let result = components.count > 1 ? String(components[1]) : ""
                            Text(result)
                                .tag(option.name)
                        }
                    }
                    .labelsHidden()
                    .disabled(HuggingChatSession.shared.currentUser == nil)
                    .onChange(of: selectedExternalModel) {
                        if let activeModel = externalModels.first(where: { $0.id == selectedExternalModel }) {
                            
                            DataService.shared.setActiveModel(ActiveModel(model: activeModel))
                            
                            // Reset conversation and activate model
                            conversationManager.model = activeModel
                            conversationManager.stopGenerating()
                            conversationManager.reset()
                        }
                    }
                })
                Toggle("Use web search", isOn: $useWebSearch)
                
                
            }, header: {
                Text("Server-Side Models")
            }, footer: {
                Text("Server-side models are more suitable for general usage or complex queries, and will run on an external server. Toggling web search will enable the model to complement its answers with information queried from the web.")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .foregroundColor(.secondary)
            })
            .disabled(HuggingChatSession.shared.currentUser == nil)
            
            Section(content: {
                KeyboardShortcuts.Recorder("HFChat Keyboard Shortcut:", name: .showFloatingPanel)
                KeyboardShortcuts.Recorder("Generation Mode Shortcut:", name: .toggleLocalGeneration)
                Toggle(isOn: $hideDock) {
                    Text("Hide dock icon")
                }
                LaunchAtLogin.Toggle {
                    Text("Open automatically at login")
                }
                Picker("Automatically clear chat after:", selection: $chatClearInterval) {
                    Text("15 minutes").tag("15min")
                    Text("1 hour").tag("1hour")
                    Text("1 day").tag("1day")
                    Text("Never").tag("never")
                }
                .onChange(of: hideDock) { oldValue, newValue in
                    if newValue == false {
                        NSApp.setActivationPolicy(.regular)
                    }
                }
            }, header: {
                Text("Miscellaneous")
            })
        }
        .onAppear {
            HuggingChatSession.shared.refreshLoginState()
            fetchModels()
            modelManager.fetchAllLocalModels()
        }
        .formStyle(.grouped)
    }
    
    // Helper methods
    func fetchModels() {
        DataService.shared.getModels()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    print("Did finish fetching models")
                case .failure(let error):
                    print("Did fail fetching models:\n\(error)")
                }
            } receiveValue: { models in
                externalModels = models.filter({ !$0.unlisted })
            }.store(in: &cancellables)
    }
}

#Preview {
    GeneralSettingsView()
        .environment(ConversationViewModel())
        .environment(ModelManager())
}
