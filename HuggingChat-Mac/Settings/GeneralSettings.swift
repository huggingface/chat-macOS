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
    
    @AppStorage("baseURL") private var baseURL: String = "https://huggingface.co"
    @AppStorage("userLoggedIn") private var userLoggedIn: Bool = false
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("hideDock") private var hideDock: Bool = false
    @AppStorage("localModel") private var selectedLocalModel: String = "None"
    @AppStorage("externalModel") private var selectedExternalModel: String = "meta-llama/Meta-Llama-3.1-70B-Instruct"
    @AppStorage("useWebSearch") private var useWebSearch = false
    @AppStorage("chatClearInterval") private var chatClearInterval: String = "never"
    @AppStorage("isLocalGeneration") private var isLocalGeneration: Bool = false
    @AppStorage("useContext") private var useContext: Bool = false
    
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
                    
                    if HuggingChatSession.shared.currentUser == nil {
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
                LabeledContent("Model Name:", content: {
                    HStack {
                        Picker("", selection: $selectedLocalModel) {
                            Text("None").tag("None")
                            let downloadedModels = modelManager.availableModels.filter { $0.localURL != nil }
                            ForEach(downloadedModels, id: \.id) { option in
                                Text(option.displayName).tag(option.displayName)
                            }
                        }
                        // Local model status
                        StatusIndicatorView(status: modelManager.loadState)
                        
                    }
                    .labelsHidden()
                    .onChange(of: selectedLocalModel) {
                        if selectedLocalModel == "None" {
                            isLocalGeneration = false
                            modelManager.cancelLoading()
                        } else if let selectedLocalModel = modelManager.availableModels.first(where: { $0.displayName == selectedLocalModel }) {
                            Task {
                                await modelManager.localModelDidChange(to: selectedLocalModel)
                            }
                        }
                    }
                })
                
            }, header: {
                Text("Local Inference")
            }, footer: {
                Text("Local models will run queries entirely on your local machine.")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .foregroundColor(.secondary)
            })
            
            Section(content: {
                LabeledContent("Model Name:", content: {
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
                            conversationManager.isMultimodal = activeModel.multimodal
                            conversationManager.isTools = activeModel.tools
                            conversationManager.stopGenerating()
                            conversationManager.reset()
                        }
                    }
                })
                Toggle("Use web search", isOn: $useWebSearch)
                
                
            }, header: {
                Text("Server-Side Inference")
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
                Toggle("Use Working Context", isOn: $useContext)
            }, header: {
                Text("Experimental")
            }, footer: {
                Text("When enabled, the model will automatically use the working context of the foremost window (e.g. text editor, selected text, terminal history) and append it to your query. Your data is never used for training.")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .foregroundColor(.secondary)
            })
            
            Section(content: {
                KeyboardShortcuts.Recorder("Global Keyboard Shortcut:", name: .showFloatingPanel)
                KeyboardShortcuts.Recorder("Toggle between local and server generation:", name: .toggleLocalGeneration)
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
//            modelManager.fetchAllLocalModels()
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
