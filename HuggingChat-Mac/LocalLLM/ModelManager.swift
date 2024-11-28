//
//  ModelManager.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/23/24.
//

import SwiftUI
import Path
import Combine
import UniformTypeIdentifiers
import MLXLLM
import MLX
import MLXRandom
import Hub

// TODO: Finalize local model loading after getting USER tokens
enum LoadState {
    case idle
    case loaded(ModelContainer)
}

enum LocalModelState: Equatable {
    case generating(Double)
    case failed(String)
    case error
}

enum ModelDownloadState: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case error(String)
    
    static func == (lhs: ModelDownloadState, rhs: ModelDownloadState) -> Bool {
        switch (lhs, rhs) {
        case (.notDownloaded, .notDownloaded):
            return true
        case (.downloaded, .downloaded):
            return true
        case let (.downloading(lhsProgress), .downloading(rhsProgress)):
            return lhsProgress == rhsProgress
        case let (.error(lhsError), .error(rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

// Local representation of HF models
@Observable class LocalModel: Identifiable, Hashable {
    var id : String = UUID().uuidString
    let displayName: String
    var size: String?
    let hfURL: String?
    var localURL: URL?
    var icon: String = "laptopcomputer"
    
    var downloadState: ModelDownloadState = .notDownloaded
    
    init(
        id: String = UUID().uuidString,
        displayName: String,
        size: String? = nil,
        hfURL: String? = nil,
        localURL: URL? = nil,
        icon: String = "laptopcomputer",
        downloadState: ModelDownloadState = .notDownloaded
    ) {
        self.id = id
        self.displayName = displayName
        self.size = size
        self.hfURL = hfURL
        self.localURL = localURL
        self.icon = icon
        self.downloadState = downloadState
    }
    
    static func == (lhs: LocalModel, rhs: LocalModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@Observable class ModelManager {
    
    var availableModels: [LocalModel] = [
        LocalModel(id: "Qwen2.5-3B-Instruct-bf16", displayName: "Qwen2.5-3B-Instruct", size: "5.2GB", hfURL: "mlx-community/Qwen2.5-3B-Instruct-bf16", localURL: nil),
        LocalModel(id: "SmolLM-135M-Instruct-4bit", displayName: "SmolLM-135M-Instruct-4bit", size: "75.8MB", hfURL: "mlx-community/SmolLM-135M-Instruct-4bit")
    ]
    private var activeDownloads: [String: Task<Void, Error>] = [:]
    
    // MLX Params
    var globalContainer: ModelContainer?
    var globalConfig: ModelConfiguration?
    let generateParameters = GenerateParameters(temperature: 0.6)
    let maxTokens = 240
    let displayEveryNTokens = 4
    var loadState = LoadState.idle
    var outputText: String = ""
    var running = false
    var messages : [[String:String]] = []
    
    init() {
        self.fetchAllLocalModels()
    }
    
    // MARK: - Model Loading
    func localModelDidChange(to model: LocalModel) async  {
        loadState = .idle
        globalConfig = ModelConfiguration(id: model.hfURL!, defaultPrompt: "")
        do {
            globalContainer = try await load(modelConfiguration: globalConfig!)
            loadState = .loaded(globalContainer!)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func load(modelConfiguration: ModelConfiguration) async throws -> ModelContainer {
        do {
            MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)
            
            let modelContainer = try await MLXLLM.loadModelContainer(
                configuration: modelConfiguration,
                progressHandler: { _ in }
            )
            
            return modelContainer
        } catch {
            throw error
        }
    }
    
    private func load(
        modelConfiguration: ModelConfiguration,
        progressCallback: @escaping @Sendable (Progress) -> Void
    ) async throws -> ModelContainer {
        do {
            MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)
            
            let modelContainer = try await MLXLLM.loadModelContainer(
                configuration: modelConfiguration,
                progressHandler: progressCallback
            )
            
            return modelContainer
        } catch {
            print(error.localizedDescription)
            throw error
        }
    }
    
    func cancelLoading() {
        loadState = .idle
        globalContainer = nil
        //        generatedText = ""
    }
    
    
    // MARK: - Download model
    func downloadModel(_ model: LocalModel) {
        guard let modelIndex = availableModels.firstIndex(where: { $0.id == model.id }) else { return }
        availableModels[modelIndex].downloadState = .downloading(progress: 0)
        
        let downloadTask = Task {
            do {
                let modelConfig = ModelConfiguration(id: model.hfURL!, defaultPrompt: "")
                let hub = HubApi()
                
                _ = try await prepareModelDirectory(
                    hub: hub,
                    configuration: modelConfig
                ) { progress in
                    Task { @MainActor in
                        if let idx = self.availableModels.firstIndex(where: { $0.id == model.id }) {
                            self.availableModels[idx].downloadState = .downloading(progress: progress.fractionCompleted)
                        }
                    }
                }
                
                // Update state to downloaded on success
                await MainActor.run {
                    if let idx = self.availableModels.firstIndex(where: { $0.id == model.id }) {
                        self.availableModels[idx].downloadState = .downloaded
                    }
                    self.fetchAllLocalModels()
                }
                
            } catch {
                await MainActor.run {
                    if let idx = self.availableModels.firstIndex(where: { $0.id == model.id }) {
                        self.availableModels[idx].downloadState = .error(error.localizedDescription)
                    }
                    self.fetchAllLocalModels()
                }
                throw error
            }
        }
        
        activeDownloads[model.id] = downloadTask
    }
    
    private func prepareModelDirectory(
        hub: HubApi, configuration: ModelConfiguration,
        progressHandler: @Sendable @escaping (Progress) -> Void
    ) async throws -> URL {
        do {
            switch configuration.id {
            case .id(let id):
                // download the model weights
                let repo = Hub.Repo(id: id)
                let modelFiles = ["*.safetensors", "config.json"]
                return try await hub.snapshot(
                    from: repo, matching: modelFiles, progressHandler: progressHandler)
                
            case .directory(let directory):
                return directory
            }
        } catch Hub.HubClientError.authorizationRequired {
            // an authorizationRequired means (typically) that the named repo doesn't exist on
            // on the server so retry with local only configuration
            return configuration.modelDirectory(hub: hub)
        } catch {
            let nserror = error as NSError
            if nserror.domain == NSURLErrorDomain && nserror.code == NSURLErrorNotConnectedToInternet {
                // Error Domain=NSURLErrorDomain Code=-1009 "The Internet connection appears to be offline."
                // fall back to the local directory
                return configuration.modelDirectory(hub: hub)
            } else {
                throw error
            }
        }
    }
    
    // MARK: - Generate Text
    func generate(prompt: String) async {
        guard !running else { return }
        guard globalContainer != nil else { return }
        guard globalConfig != nil else { return }

        running = true
        self.outputText = ""

        do {
            messages.append(["role": "user", "content": prompt])
            let promptTokens = try await globalContainer!.perform { _, tokenizer in
                try tokenizer.applyChatTemplate(messages: messages)
            }

            MLXRandom.seed(UInt64(Date.timeIntervalSinceReferenceDate * 1000))

            let result = await globalContainer!.perform { model, tokenizer in
                MLXLLM.generate(
                    promptTokens: promptTokens, parameters: generateParameters, model: model,
                    tokenizer: tokenizer, extraEOSTokens: globalConfig!.extraEOSTokens
                ) { tokens in
                    // update the output -- this will make the view show the text as it generates
                    if tokens.count % displayEveryNTokens == 0 {
                        let text = tokenizer.decode(tokens: tokens)
                        Task { @MainActor in
                            self.outputText = text
                        }
                    }

                    if tokens.count >= maxTokens {
                        return .stop
                    } else {
                        return .more
                    }
                }
            }

            // update the text if needed, e.g. we haven't displayed because of displayEveryNTokens
            if result.output != self.outputText {
                self.outputText = result.output
                messages.append(["role": "system", "content": result.output])
            }
//            self.stat = " Tokens/second: \(String(format: "%.3f", result.tokensPerSecond))"

        } catch {
            outputText = "Failed: \(error)"
        }

        running = false
    }
    
    func clearText() {
        messages = []
        outputText = ""
    }
    
    // MARK: - Helper functions
    func fetchAllLocalModels() {
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                let items = try FileManager.default.contentsOfDirectory(at: documentsPath.appendingPathComponent("huggingface").appendingPathComponent("models").appendingPathComponent("mlx-community"), includingPropertiesForKeys: [.isDirectoryKey])
                let downloadedModelNames = Set(items.map { $0.lastPathComponent })
                for (index, model) in availableModels.enumerated() {
                    if let hfURL = model.hfURL {
                        let modelName = hfURL.split(separator: "/").last.map(String.init) ?? ""
                        
                        if downloadedModelNames.contains(modelName) {
                            if let modelPath = items.first(where: { $0.lastPathComponent == modelName }) {
                                let fileSize = getDirectorySize(url: modelPath.standardizedFileURL)
                                
                                // Update the model with local info
                                availableModels[index].downloadState = .downloaded
                                availableModels[index].localURL = modelPath
                                availableModels[index].size = fileSize
                            }
                        } else {
                            // Reset properties if model isn't found locally
                            availableModels[index].downloadState = .notDownloaded
                            availableModels[index].localURL = nil
                            
                        }
                    }
                 }
            } catch {
                print("Error fetching local models: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteLocalModel(_ model: LocalModel) {
        guard let localURL = model.localURL else { return }
        do {
            try Path(url: localURL)?.delete()
        } catch {
            print("Error deleting local model: \(error)")
        }
    }
    
    func getFileSize(url: URL) -> String {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            guard let fileSizeBytes = resourceValues.fileSize else {
                return "File size unavailable"
            }
            
            let fileSizeMB = Double(fileSizeBytes) / (1024 * 1024)
            let fileSizeGB = fileSizeMB / 1024
            
            if fileSizeGB >= 1 {
                return String(format: "%.2f GB", fileSizeGB)
            } else {
                return String(format: "%.2f MB", fileSizeMB)
            }
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
    
    func getDirectorySize(url: URL) -> String {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]) else {
            print("Failed to create enumerator for \(url)")
            return "0 GB"
        }
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                
                if let isDirectory = resourceValues.isDirectory, isDirectory {
                    continue
                }
                
                if let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            } catch {
                print("Error getting size of file \(fileURL): \(error)")
            }
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        let sizeInBytes = Int(exactly: totalSize) ?? Int.max
        let formattedSize = formatter.string(fromByteCount: Int64(sizeInBytes))
        
        return formattedSize
    }
}
