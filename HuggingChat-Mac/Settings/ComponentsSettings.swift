//
//  ComponentsSettings.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/22/24.
//

import SwiftUI
import MLXLLM
//import WhisperKit

struct ComponentsSettingsView: View {
    
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
                                                modelManager.downloadModel(model)
                                                
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
                                            modelManager.downloadModel(model)
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
                Section("Suggested") {
                    ForEach(modelManager.availableModels) { localModel in
                        TableRow(localModel)
                    }
                }
            }
            .contextMenu(forSelectionType: LocalModel.ID.self) { items in
                if !items.isEmpty {
                    let selectedModels = items.compactMap { itemId in
                        modelManager.availableModels.first(where: { $0.id == itemId })
                    }
                    
                    // Only show delete if any selected model is downloaded
                    if selectedModels.contains(where: { $0.downloadState == .downloaded }) {
                        Button(role: .destructive) {
                            for model in selectedModels where model.downloadState == .downloaded {
                                modelManager.deleteLocalModel(model)
                            }
                            modelManager.fetchAllLocalModels()
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
            .padding(.horizontal, 10)
        }
//        .onAppear {
//            audioModelManager.fetchModels()
//        }
    }
    
    
    // MARK: - Private functions
    func formatAudioModelName(_ input: String) -> String {
        let words = input.components(separatedBy: CharacterSet(charactersIn: "-_"))
        var formatted = words.map { $0.capitalized }.joined(separator: " ")
        formatted = formatted.replacingOccurrences(of: "openai", with: "OpenAI", options: .caseInsensitive)
        return formatted
    }
    
//    func fetchModelURL(model: String) -> URL? {
//        if audioModelManager.localModels.contains(model) {
//            return URL(fileURLWithPath: model)
//        } else {
//            return nil
//        }
//    }
//    
//    func fetchModelSize(model: String) -> String {
//        print(audioModelManager.localModels.contains(model))
//        if audioModelManager.localModels.contains(model) {
//            return audioModelManager.getDirectorySize(selectedModel: WhisperKit.recommendedModels().default)
//        } else {
//            return "--"
//        }
//    }
}

#Preview {
    ComponentsSettingsView()
        .environment(ModelManager())
//        .environment(AudioModelManager())
}
