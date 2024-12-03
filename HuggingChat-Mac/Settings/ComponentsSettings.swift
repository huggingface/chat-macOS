//
//  ComponentsSettings.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/22/24.
//

import SwiftUI
import MLXLLM
import WhisperKit

struct ComponentsSettingsView: View {
    
    @Environment(AudioModelManager.self) private var audioModelManager
    @Environment(ModelManager.self) private var modelManager
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedModels = Set<LocalModel.ID>()
    @State private var showFilePicker = false
    
    var body: some View {
        VStack {
            Table(of: LocalModel.self, selection: $selectedModels) {
                TableColumn("Name") { model in
                    Label(model.displayName, systemImage: model.icon)
                        .symbolRenderingMode(.hierarchical)
                }
                
                TableColumn("Info") { model in
                        HStack {
                                switch model.downloadState {
                                case .notDownloaded:
                                    if model.localURL != nil {
                                        Text("\(model.size ?? "") on disk")
                                            .frame(height: 20)
                                    } else {
                                        HStack {
                                            Text(model.size ?? "--")
                                            Button(action: {
                                                
                                                switch model.modelType {
                                                case .llm:
                                                    modelManager.downloadModel(model)
                                                case .stt:
                                                    audioModelManager.downloadModel(model)
                                                }
                                            }) {
                                                Text("GET")
                                                    .fontWeight(.medium)
                                                    .controlSize(.small)
                                                    .buttonStyle(.plain)
                                                    .frame(width: 50, height: 20)
                                                    .foregroundStyle(.blue)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 15)
                                                            .fill(colorScheme == .dark ? .white : Color(red: 242/255, green: 242/255, blue: 247/255))
                                                    )
                                            }
                                        }
                                    }
                                case .downloading(let progress):
                                    HStack(spacing: 8) {
                                        Text("\(Int(progress * 100))%")
                                            .foregroundStyle(.secondary)
                                        ProgressView(value: progress)
                                            .frame(width: 60)
                                            .progressViewStyle(.circular)
                                            .controlSize(.mini)
                                            .frame(width: 20, height: 20)
//                                        Button(action: {
//                                            modelManager.cancelDownload(for: model.id)
//                                        }) {
//                                            Image(systemName: "xmark.circle.fill")
//                                                .foregroundStyle(.secondary)
//                                        }
                                    }
                                case .downloaded:
                                    Text("\(model.size ?? "") on disk")
                                        .frame(height: 20)
                                case .error(let message):
                                    HStack {
                                        Button(action: {}) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundStyle(.secondary)
                                        }
                                        .help(message)
                                        Button(action: {
                                            switch model.modelType {
                                            case .llm:
                                                modelManager.downloadModel(model)
                                            case .stt:
                                                audioModelManager.downloadModel(model)
                                            }
                                        }) {
                                            Text("GET")
                                                .fontWeight(.medium)
                                                .controlSize(.small)
                                                .buttonStyle(.plain)
                                                .frame(width: 50, height: 20)
                                                .foregroundStyle(.blue)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 15)
                                                        .fill(colorScheme == .dark ? .white : Color(red: 242/255, green: 242/255, blue: 247/255))
                                                )
                                        }
                                    }
                                }
                        }
                    
                    
                }
                .alignment(.trailing)
            } rows: {
                Section("Language Models") {
                    ForEach(modelManager.availableModels) { localModel in
                        TableRow(localModel)
                    }
                }
                
                Section("Audio Models") {
                    ForEach(audioModelManager.availableLocalModels) { audioModel in
                        TableRow(audioModel)
                    }
                }
            }
            .contextMenu(forSelectionType: LocalModel.ID.self) { items in
                if !items.isEmpty {
                    let selectedLLMModels = items.compactMap { itemId in
                        modelManager.availableModels.first(where: { $0.id == itemId })
                    }
                    
                    let selectedAudioModels = items.compactMap { itemId in
                        audioModelManager.availableLocalModels.first(where: { $0.id == itemId })
                    }
                    
                    // Only show delete if any selected model is downloaded
                    if selectedLLMModels.contains(where: { $0.downloadState == .downloaded }) {
                        Button(role: .destructive) {
                            for model in selectedLLMModels where model.downloadState == .downloaded {
                                modelManager.deleteLocalModel(model)
                            }
                            modelManager.fetchAllLocalModels()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    
                    if selectedAudioModels.contains(where: { $0.downloadState == .downloaded }) {
                        Button(role: .destructive) {
                            for model in selectedAudioModels where model.downloadState == .downloaded {
                                audioModelManager.deleteModel(selectedModel: model.id)
                            }
                            audioModelManager.fetchModels()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .tableStyle(.automatic)
            .alternatingRowBackgrounds(.disabled)
        
            HStack(alignment: .center) {
                Button(action: {
                    for localModelID in selectedModels {
                        if let modelToDelete = modelManager.availableModels.first(where: {$0.id == localModelID}) {
                            modelManager.deleteLocalModel(modelToDelete)
                            self.modelManager.fetchAllLocalModels()
                        } else if let modelToDelete = audioModelManager.availableLocalModels.first(where: {$0.id == localModelID}) {
                            audioModelManager.deleteModel(selectedModel: modelToDelete.id)
                            self.audioModelManager.fetchModels()
                        }
                    }
                   
                }) {
                    Image(systemName: "minus").imageScale(.medium)
                }
                .disabled(selectedModels.isEmpty)
                
                Spacer()
            }
            
            .buttonStyle(.borderless)
            .frame(height: 20)
            .padding(.horizontal, 10)
        }
        .onAppear {
            audioModelManager.fetchModels()
        }
    }
}

#Preview {
    ComponentsSettingsView()
        .environment(ModelManager())
        .environment(AudioModelManager())
}
