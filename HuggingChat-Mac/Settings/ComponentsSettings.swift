//
//  ComponentsSettings.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/22/24.
//

import SwiftUI
import WhisperKit

struct ComponentsSettingsView: View {
    
    @Environment(ModelManager.self) private var modelManager
    @Environment(AudioModelManager.self) private var audioModelManager
    @Environment(ModelDownloader.self) private var modelDownloader
    @Environment(\.colorScheme) private var colorScheme
    
    @AppStorage("selectedAudioModel") private var selectedModel: String = "None"
    @State private var selectedModels = Set<LocalModel.ID>()
    @State private var showFilePicker = false
    
    var body: some View {
        VStack {
            Table(of: LocalModel.self, selection: $selectedModels) {
                TableColumn("Name") { model in
                    Label(model.name, systemImage: model.icon)
                        .symbolRenderingMode(.hierarchical)
                }
//                TableColumn("Date Created") { model in
//                    if let lastUsed = model.lastUsed {
//                        TimelineView(.everyMinute) { context in
//                            Text(lastUsed)
//                        }
//                    } else {
//                        Text("--")
//                    }
//                    
//                }
                
                TableColumn("Info") { model in
                    if model.localURL != nil {
                        Text("\(model.sizeInfo ?? "") on disk")
                        // TODO: Add Button to delete local model
                    } else {
                        HStack {
                            // TODO: Replace this with donwnloading when available
                            // Check if Mistral. If Mistral navigate to page
                            // Otherwise download and load in the background.
                            if model.name == "Llama 3.2 3B Instruct" {
                                Text(model.sizeInfo ?? "--")
                                if let hfURL = model.hfURL {
                                    Link(destination: URL(string: "https://huggingface.co/\(hfURL)")!) {
                                        Text("GET")
                                            .fontWeight(.medium)
                                            .controlSize(.small)
                                            .buttonStyle(.plain)
                                            .frame(width: 50, height: 20)
                                            .foregroundStyle(.blue)
                                            .background(RoundedRectangle(cornerRadius: 15).fill(
                                                colorScheme == .dark ? .white : .gray.opacity(0.2)
                                            ))
                                    }
                                }
                            } else {
                                // TODO: On appear check that the recommended model isn't already downloaded.
                                // Download the whisperKit models
                                Text(model.sizeInfo ?? "--")
                                if (audioModelManager.downloadingModels[model.name] == nil || audioModelManager.downloadingModels[model.name] == false) && model.localURL == nil {
                                    Button(action: {
                                        audioModelManager.downloadingModels[model.name] = true
                                        audioModelManager.downloadModel(WhisperKit.recommendedModels().default)
                                        
                                    }, label: {
                                        Text("GET")
                                            .fontWeight(.medium)
                                            .controlSize(.small)
                                            .buttonStyle(.plain)
                                            .frame(width: 50, height: 20)
                                            .foregroundStyle(.blue)
                                            .background(RoundedRectangle(cornerRadius: 15).fill(
                                                colorScheme == .dark ? .white : .gray.opacity(0.2)
                                            ))
                                    })
                                } else if (audioModelManager.downloadingModels[model.name] == true) && model.localURL == nil {
                                    HStack {
                                        Text("\(audioModelManager.loadingProgressValue * 100, specifier: "%.0f")%")
                                        ProgressView("", value: audioModelManager.loadingProgressValue, total: 1)
                                            .progressViewStyle(.circular)
                                            .tint(.accentColor)
                                            .controlSize(.mini)
                                            .labelsHidden()
                                    }
                                    .frame(maxWidth: 75)
                                }
                            }
                        }
                    }
                    
                }
                .alignment(.trailing)
            } rows: {
                Section("Recommended") {
                    TableRow(LocalModel(id: "recommended-llm", name: "Llama 3.2 3B Instruct", lastUsed: "--", sizeInfo: "2.02GB", hfURL: "hugging-quants/Llama-3.2-3B-Instruct-Q4_K_M-GGUF", localURL: nil))
                    
//                    TableRow(LocalModel(id: "recommended-audio", name: formatAudioModelName(WhisperKit.recommendedModels().default), lastUsed: audioModelManager.getFileCreationDate(for: WhisperKit.recommendedModels().default), sizeInfo: fetchModelSize(model: WhisperKit.recommendedModels().default), hfURL: "argmaxinc/whisperkit-coreml", localURL: fetchModelURL(model: WhisperKit.recommendedModels().default), icon: "waveform.badge.mic"))
//                        .contextMenu {
//                            Button(action: {
//                                audioModelManager.deleteModel(selectedModel: WhisperKit.recommendedModels().default)
//                                audioModelManager.fetchModels()
//                                if selectedModel == WhisperKit.recommendedModels().default {
//                                    selectedModel = "None"
//                                }
//                            }, label: {
//                                Label("Delete", systemImage: "trash")
//                            })
//                        }
                }
                Section("Imported") {
                    ForEach(modelManager.availableModels) { localModel in
                        TableRow(localModel)
                    }
                }
            }
            .tableStyle(.automatic)
        
            HStack(alignment: .center) {
                Button(action: {
                    showFilePicker.toggle()
                }) {
                    Image(systemName: "plus").imageScale(.medium)
                }
                
                Button(action: {
                    for localModelID in selectedModels {
                        if let modelToDelete = modelManager.availableModels.first(where: {$0.id == localModelID}) {
                            modelManager.deleteLocalModel(modelToDelete)
                        }
                    }
                    self.modelManager.fetchAllLocalModels()
                }) {
                    Image(systemName: "minus").imageScale(.medium)
                }
                .disabled(selectedModels.isEmpty)
                
                Spacer()
            }
            
            .buttonStyle(.borderless)
            .frame(height: 20)
            .padding(10)
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.gguf], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                for modelURL in urls {
                    if modelURL.startAccessingSecurityScopedResource() {
                        modelManager.saveLocalModel(using: modelURL)
                        modelURL.stopAccessingSecurityScopedResource()
                    }
                }
                modelManager.fetchAllLocalModels()
            case .failure(let error):
                print("Import failed: \(error.localizedDescription)")
            }
        }
        .onAppear {
            audioModelManager.fetchModels()
        }
    }
    
    
    // MARK: - Private functions
    func formatAudioModelName(_ input: String) -> String {
        let words = input.components(separatedBy: CharacterSet(charactersIn: "-_"))
        var formatted = words.map { $0.capitalized }.joined(separator: " ")
        formatted = formatted.replacingOccurrences(of: "openai", with: "OpenAI", options: .caseInsensitive)
        return formatted
    }
    
    func fetchModelURL(model: String) -> URL? {
        if audioModelManager.localModels.contains(model) {
            return URL(fileURLWithPath: model)
        } else {
            return nil
        }
    }
    
    func fetchModelSize(model: String) -> String {
        print(audioModelManager.localModels.contains(model))
        if audioModelManager.localModels.contains(model) {
            return audioModelManager.getDirectorySize(selectedModel: WhisperKit.recommendedModels().default)
        } else {
            return "--"
        }
    }
}

#Preview {
    ComponentsSettingsView()
        .environment(ModelManager())
        .environment(ModelDownloader())
        .environment(AudioModelManager())
}
