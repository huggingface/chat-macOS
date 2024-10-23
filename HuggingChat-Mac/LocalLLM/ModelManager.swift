//
//  ModelManager.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/23/24.
//

import SwiftUI
import Path
import Combine
import Models
import Generation
import UniformTypeIdentifiers

// TODO: Finalize local model loading after getting USER tokens

enum LocalModelState: Equatable {
    case noModel
    case loading
    case ready(Double?)
    case generating(Double)
    case failed(String)
    case error
}

// Local representation of HF models
struct LocalModel: Identifiable, Hashable {
    var id : String = UUID().uuidString
    let name: String
    var lastUsed: String?
    var sizeInfo: String?
    let hfURL: String?
    let localURL: URL?
    var icon: String = "laptopcomputer"
}

@Observable class ModelManager {
    
    
    var availableModels: [LocalModel] = []
    var status: LocalModelState = .noModel
    var generatedText: String = ""
    
    // Llama model properties
    var swiftLlama: SwiftLlama?
    var usingStream = true
    private var cancellable: Set<AnyCancellable> = []
    
    // CoreML model properties
    var coreMLModel: LanguageModel? = nil
    var config = GenerationConfig(maxNewTokens: 1000) // What's a good default value?
    var outputText: AttributedString = ""
    
    // Errors
    var local_error: LlamaError?
    
    init() {
        self.fetchAllLocalModels()
    }
    
    // MARK: - Common Core
    func localModelDidChange(to model: LocalModel) {
        if let localURL = model.localURL {
            if localURL.pathExtension.lowercased() == "gguf" {
                status = .loading
                Task {
                    do {
                        swiftLlama = try SwiftLlama(modelPath: localURL.path(), modelConfiguration: .init())
                        status = .ready(nil)
                    } catch {
                        local_error = LlamaError.others("Model could not be loaded: \(error.localizedDescription)")
                        status = .noModel
                    }
                }
            }
        }

        
        
//        guard status != .loading else { return }
//        
//        status = .loading
//        Task {
//            do {
//                coreMLModel = try await ModelLoader.load(url: model.localURL)
//                if let config = coreMLModel?.defaultGenerationConfig {
//                    let maxNewTokens = self.config.maxNewTokens
//                    self.config = config
//                    self.config.maxNewTokens = maxNewTokens
//                }
//                status = .ready(nil)
//            } catch {
//                print("No model could be loaded: \(error)")
//                status = .noModel
//            }
//        }
    }
    
    func cancelLoading() {
        status = .noModel
        generatedText = ""
        self.swiftLlama = nil
        self.coreMLModel = nil
        Task {
            try await ModelLoader.load(url: nil)
        }
        // TODO: proper check for coreML model being released from memory
    }
    
    func fetchAllLocalModels() {
        availableModels = []
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                let items = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: [.isDirectoryKey])
                for item in items {
                    let fileExtension = item.pathExtension.lowercased()
                    if fileExtension == "mlpackage" || fileExtension == "mlmodelc" || fileExtension == "gguf" {
                        // CoreML Stuff
                        let isDirectory = (try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                        if isDirectory {
                            let creationDate = getFileCreationDate(for: item.standardizedFileURL)
                            let fileSize = getDirectorySize(url: item.standardizedFileURL)
                            let downloadedModel = LocalModel(
                                name: item.deletingPathExtension().lastPathComponent,
                                lastUsed: creationDate,
                                sizeInfo: fileSize,
                                hfURL: nil,
                                localURL: item
                            )
                            availableModels.append(downloadedModel)
                        } else {
                            // GGUF stuff
                            let creationDate = getFileCreationDate(for: item.standardizedFileURL)
                            let fileSize = getFileSize(url: item.standardizedFileURL)
                            let downloadedModel = LocalModel(
                                name: item.deletingPathExtension().lastPathComponent,
                                lastUsed: creationDate,
                                sizeInfo: fileSize,
                                hfURL: nil,
                                localURL: item
                            )
                            availableModels.append(downloadedModel)
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
    
    func saveLocalModel(using sourceURL: URL) {
        //        Task {
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let destinationURL = documentsPath.appendingPathComponent(sourceURL.lastPathComponent)
            do {
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            } catch {
                print(error.localizedDescription)
            }
            
            //            }
        }
    }
    
    // MARK: - Llama CPP
    func generateCPP(text: String) {
        status = .generating(0)
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let swiftLlama else {
            local_error = .others("SwiftLlama is not initialized")
            status = .error
            return
        }
        
        // Stop generation if message is sent
        generatedText = ""
        swiftLlama.cancelGeneration()
        
        Task {
            do {
                switch usingStream {
                case true:
                    do {
                        for try await value in await swiftLlama.start(for: text) {
                            generatedText += value
                        }
                    } catch {
                        throw error
                    }
                case false:
                    await swiftLlama.start(for: text)
                        .sink { completion in
                            switch completion {
                            case .finished:
                                break
                            case .failure(let error):
                                self.local_error = .others(error.localizedDescription)
                                self.status = .error
                            }
                        } receiveValue: { [weak self] value in
                            self?.generatedText += value
                        }.store(in: &cancellable)
                }
                
                swiftLlama.logResponse(for: generatedText)
                DispatchQueue.main.async {
                    self.status = .ready(0)
                }
            } catch {
                await handleError(error)
            }
        }
    }

    @MainActor
    private func handleError(_ error: Error) {
        if let llamaError = error as? LlamaError {
            self.local_error = llamaError
            print("LlamaError: \(llamaError.description)")
        } else {
            self.local_error = .others(error.localizedDescription)
            print("Other error: \(error.localizedDescription)")
        }
        status = .error
    }
    
    func clearText() {
        generatedText = ""
        if let swiftLlama {
            swiftLlama.clearSession()
        }
    }
    
    // MARK: - CoreML
    func predictText(for prompt: String) {
        guard let coreMLModel = coreMLModel else { return }
        
        @Sendable func showOutput(currentGeneration: String, progress: Double, completedTokensPerSecond: Double? = nil) {
            Task { @MainActor in
                // Temporary hack to remove start token returned by llama tokenizers
                var response = currentGeneration.deletingPrefix("<s> ")
                
                // Strip prompt
                guard response.count > prompt.count else { return }
                response = response[prompt.endIndex...].replacingOccurrences(of: "\\n", with: "\n")
                
                // Format prompt + response with different colors
                var styledPrompt = AttributedString(prompt)
                styledPrompt.foregroundColor = .black
                
                var styledOutput = AttributedString(response)
                styledOutput.foregroundColor = .accentColor
                
                outputText = styledPrompt + styledOutput
                if let tps = completedTokensPerSecond {
                    status = .ready(tps)
                } else {
                    status = .generating(progress)
                }
            }
        }
        
        Task.init {
            status = .generating(0)
            var tokensReceived = 0
            let begin = Date()
            do {
                let output = try await coreMLModel.generate(config: config, prompt: prompt) { inProgressGeneration in
                    tokensReceived += 1
                    showOutput(currentGeneration: inProgressGeneration, progress: Double(tokensReceived)/Double(self.config.maxNewTokens))
                }
                let completionTime = Date().timeIntervalSince(begin)
                let tokensPerSecond = Double(tokensReceived) / completionTime
                showOutput(currentGeneration: output, progress: 1, completedTokensPerSecond: tokensPerSecond)
                print("Took \(completionTime)")
            } catch {
                print("Error \(error)")
                Task { @MainActor in
                    status = .failed("\(error)")
                }
            }
        }
    }
    
    // MARK: - Helper functions
    private func getFileCreationDate(for filePath: URL) -> String? {
        // TODO: Fix so less granular.
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: filePath.path()),
              let creationDate = attributes[.creationDate] as? Date else {
            return nil
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: creationDate, relativeTo: Date())
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
