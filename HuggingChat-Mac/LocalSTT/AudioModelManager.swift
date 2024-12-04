//
//  AudioModelManager.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 9/9/24.
//

import SwiftUI
import WhisperKit
import AppKit
import AVFoundation
import CoreML

enum TranscriptionMode {
    case streaming
    case recording
}

@Observable class AudioModelManager {
    
    var whisperKit: WhisperKit? = nil
    var audioDevices: [AudioDevice]? = nil
    var isRecording: Bool = false
    var isTranscribing: Bool = false
    var currentText: String = ""
    var currentChunks: [Int: (chunkText: [String], fallbacks: Int)] = [:]
    var modelStorage: String = "huggingface/models/argmaxinc/whisperkit-coreml"
    
    var modelState: ModelState = .unloaded
    var localModels: [String] = []
    var localModelPath: String = ""
    var availableModels: [String] = []
    var availableLanguages: [String] = []
    var disabledModels: [String] = WhisperKit.recommendedModels().disabled
    var repoName: String = "argmaxinc/whisperkit-coreml"
    var selectedAudioInput: String = "None"
    var silenceThreshold: Double = 0.3
    var isTranscriptionComplete: Bool = false
    
    private var selectedTask: String = "transcribe"
    private var selectedLanguage: String = "english"
    private var enableTimestamps: Bool = false
    private var enablePromptPrefill: Bool = true
    private var enableCachePrefill: Bool = true
    private var enableSpecialCharacters: Bool = false
    private var enableEagerDecoding: Bool = true
    private var temperatureStart: Double = 0
    private var fallbackCount: Double = 5
    private var compressionCheckWindow: Double = 60
    private var sampleLength: Double = 224
    private var useVAD: Bool = false
    private var tokenConfirmationsNeeded: Double = 2
    private var chunkingStrategy: ChunkingStrategy = .none
    private var encoderComputeUnits: MLComputeUnits = .cpuAndNeuralEngine
    private var decoderComputeUnits: MLComputeUnits = .cpuAndNeuralEngine

    // MARK: Standard properties
    var loadingProgressValue: Float = 0.0
    var specializationProgressRatio: Float = 0.7
    var firstTokenTime: TimeInterval = 0
    var pipelineStart: TimeInterval = 0
    var effectiveRealTimeFactor: TimeInterval = 0
    var effectiveSpeedFactor: TimeInterval = 0
    var totalInferenceTime: TimeInterval = 0
    var tokensPerSecond: TimeInterval = 0
    var currentLag: TimeInterval = 0
    var currentFallbacks: Int = 0
    var currentEncodingLoops: Int = 0
    var currentDecodingLoops: Int = 0
    var lastBufferSize: Int = 0
    var lastConfirmedSegmentEndSeconds: Float = 0
    var requiredSegmentsForConfirmation: Int = 4
    var bufferEnergy: [Float] = []
    var bufferSeconds: Double = 0
    var confirmedSegments: [TranscriptionSegment] = []
    var unconfirmedSegments: [TranscriptionSegment] = []

    // MARK: Eager mode properties
    var eagerResults: [TranscriptionResult?] = []
    var prevResult: TranscriptionResult?
    var lastAgreedSeconds: Float = 0.0
    var prevWords: [WordTiming] = []
    var lastAgreedWords: [WordTiming] = []
    var confirmedWords: [WordTiming] = []
    var confirmedText: String = ""
    var hypothesisWords: [WordTiming] = []
    var hypothesisText: String = ""

    // MARK: UI properties
    private var transcriptionMode: TranscriptionMode = .recording
    private var transcriptionTask: Task<Void, Never>? = nil
    private var transcribeTask: Task<Void, Never>? = nil
    
    
    // MARK: Compatibility
    var availableLocalModels: [LocalModel] = [
        LocalModel(id: WhisperKit.recommendedModels().default, displayName: WhisperKit.recommendedModels().default.capitalized, size: "", hfURL: "argmaxinc/whisperkit-coreml/\(WhisperKit.recommendedModels().default)", localURL: nil, icon: "waveform.badge.mic", modelType: .stt)
    ]
 
   // MARK: Model Management
    func resetState() {
        transcribeTask?.cancel()
        isRecording = false
        isTranscribing = false
        whisperKit?.audioProcessor.stopRecording()
        currentText = ""
        currentChunks = [:]

        pipelineStart = Double.greatestFiniteMagnitude
        firstTokenTime = Double.greatestFiniteMagnitude
        effectiveRealTimeFactor = 0
        effectiveSpeedFactor = 0
        totalInferenceTime = 0
        tokensPerSecond = 0
        currentLag = 0
        currentFallbacks = 0
        currentEncodingLoops = 0
        currentDecodingLoops = 0
        lastBufferSize = 0
        lastConfirmedSegmentEndSeconds = 0
        requiredSegmentsForConfirmation = 2
        bufferEnergy = []
        bufferSeconds = 0
        confirmedSegments = []
        unconfirmedSegments = []

        eagerResults = []
        prevResult = nil
        lastAgreedSeconds = 0.0
        prevWords = []
        lastAgreedWords = []
        confirmedWords = []
        confirmedText = ""
        hypothesisWords = []
        hypothesisText = ""
    }
 
    func updateProgressBar(targetProgress: Float, maxTime: TimeInterval) async {
        let initialProgress = loadingProgressValue
        let decayConstant = -log(1 - targetProgress) / Float(maxTime)

        let startTime = Date()

        while true {
            let elapsedTime = Date().timeIntervalSince(startTime)

            // Break down the calculation
            let decayFactor = exp(-decayConstant * Float(elapsedTime))
            let progressIncrement = (1 - initialProgress) * (1 - decayFactor)
            let currentProgress = initialProgress + progressIncrement

            await MainActor.run {
                loadingProgressValue = currentProgress
            }

            if currentProgress >= targetProgress {
                break
            }

            do {
                try await Task.sleep(nanoseconds: 100_000_000)
            } catch {
                break
            }
        }
    }
  
    func getComputeOptions() -> ModelComputeOptions {
        return ModelComputeOptions(audioEncoderCompute: encoderComputeUnits, textDecoderCompute: decoderComputeUnits)
    }
    
    func downloadModel(_ model: LocalModel, redownload: Bool = false) {
        guard let modelIndex = availableLocalModels.firstIndex(where: { $0.id == model.id }) else { return }
        print("Selected Model: \(UserDefaults.standard.string(forKey: "selectedModel") ?? "nil")")
        print("""
            Computing Options:
            - Mel Spectrogram:  \(getComputeOptions().melCompute.description)
            - Audio Encoder:    \(getComputeOptions().audioEncoderCompute.description)
            - Text Decoder:     \(getComputeOptions().textDecoderCompute.description)
            - Prefill Data:     \(getComputeOptions().prefillCompute.description)
        """)

        whisperKit = nil
        
        Task {
            whisperKit = try await WhisperKit(
                computeOptions: getComputeOptions(),
                verbose: true,
                logLevel: .debug,
                prewarm: false,
                load: false,
                download: false
            )
            guard let _ = whisperKit else {
                return
            }
            
            // Check if the model is available locally
            if localModels.contains(model.id) && !redownload {
                // Get local model folder URL from localModels
                await MainActor.run {
                    loadingProgressValue = 1.0
                }
            } else {
                // Download the model
                availableLocalModels[modelIndex].downloadState = .downloading(progress: 0)
                _ = try await WhisperKit.download(variant: model.id, from: repoName, progressCallback: { progress in
                    DispatchQueue.main.async {
                        self.availableLocalModels[modelIndex].downloadState = .downloading(progress: progress.fractionCompleted)
                    }
                })
                
                await MainActor.run {
                    self.availableLocalModels[modelIndex].downloadState = .downloaded
                    
                    if !localModels.contains(model.id) {
                        localModels.append(model.id)
                    }
                    fetchModels()
                }
            }
        }
    }
    
    func loadModel(_ model: String, redownload: Bool = false) {
        print("Selected Model: \(UserDefaults.standard.string(forKey: "selectedModel") ?? "nil")")
        print("""
            Computing Options:
            - Mel Spectrogram:  \(getComputeOptions().melCompute.description)
            - Audio Encoder:    \(getComputeOptions().audioEncoderCompute.description)
            - Text Decoder:     \(getComputeOptions().textDecoderCompute.description)
            - Prefill Data:     \(getComputeOptions().prefillCompute.description)
        """)

        whisperKit = nil
        Task {
            whisperKit = try await WhisperKit(
                computeOptions: getComputeOptions(),
                verbose: true,
                logLevel: .debug,
                prewarm: false,
                load: false,
                download: false
            )
            guard let whisperKit = whisperKit else {
                return
            }

            var folder: URL?

            // Check if the model is available locally
            if localModels.contains(model) && !redownload {
                // Get local model folder URL from localModels
                // TODO: Make this configurable in the UI
                folder = URL(fileURLWithPath: localModelPath).appendingPathComponent(model)
            } else {
                // Download the model
                folder = try await WhisperKit.download(variant: model, from: repoName, progressCallback: { progress in
                    DispatchQueue.main.async {
                        self.loadingProgressValue = Float(progress.fractionCompleted) * self.specializationProgressRatio
                        self.modelState = .downloading
                    }
                })
            }

            await MainActor.run {
                loadingProgressValue = specializationProgressRatio
                modelState = .downloaded
            }

            if let modelFolder = folder {
                whisperKit.modelFolder = modelFolder

                await MainActor.run {
                    // Set the loading progress to 90% of the way after prewarm
                    loadingProgressValue = specializationProgressRatio
                    modelState = .prewarming
                }

                let progressBarTask = Task {
                    await updateProgressBar(targetProgress: 0.9, maxTime: 240)
                }

                // Prewarm models
                do {
                    try await whisperKit.prewarmModels()
                    progressBarTask.cancel()
                } catch {
                    print("Error prewarming models, retrying: \(error.localizedDescription)")
                    progressBarTask.cancel()
                    if !redownload {
                        loadModel(model, redownload: true)
                        return
                    } else {
                        // Redownloading failed, error out
                        modelState = .unloaded
                        return
                    }
                }

                await MainActor.run {
                    // Set the loading progress to 90% of the way after prewarm
                    loadingProgressValue = specializationProgressRatio + 0.9 * (1 - specializationProgressRatio)
                    modelState = .loading
                }

                try await whisperKit.loadModels()

                await MainActor.run {
                    if !localModels.contains(model) {
                        localModels.append(model)
                    }

                    availableLanguages = Constants.languages.map { $0.key }.sorted()
                    loadingProgressValue = 1.0
                    modelState = whisperKit.modelState
                }
            }
        }
    }
 
    func fetchModels() {
        availableModels = []

        // First check what's already downloaded
        if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let modelPath = documents.appendingPathComponent(modelStorage).path
            // Check if the directory exists
            if FileManager.default.fileExists(atPath: modelPath) {
                localModelPath = modelPath
                do {
                    let downloadedModels = try FileManager.default.contentsOfDirectory(atPath: modelPath)
                    for model in downloadedModels where !localModels.contains(model) {
                        localModels.append(model)
                    }
                } catch {
                    print("Error enumerating files at \(modelPath): \(error.localizedDescription)")
                }
            }
        }

        localModels = WhisperKit.formatModelFiles(localModels)
        for availableLocalModel in availableLocalModels {
            if localModels.contains(availableLocalModel.id) {
                let fileSize = getDirectorySize(selectedModel: availableLocalModel.id)
                availableLocalModel.downloadState = .downloaded
                availableLocalModel.localURL = URL(fileURLWithPath: localModelPath).appendingPathComponent(availableLocalModel.id)
                availableLocalModel.size = fileSize
            } else {
                availableLocalModel.downloadState = .notDownloaded
                availableLocalModel.localURL = nil
                availableLocalModel.size = nil
            }
        }
//        for dwnModel in localModels {
//            if let modelIndex = availableLocalModels.firstIndex(where: { $0.id == dwnModel }) {
//                let fileSize = getDirectorySize(selectedModel: dwnModel)
//                availableLocalModels[modelIndex].downloadState = .downloaded
//                availableLocalModels[modelIndex].localURL = URL(fileURLWithPath: localModelPath).appendingPathComponent(dwnModel)
//                availableLocalModels[modelIndex].size = fileSize
//            }
//        }
        
//        for model in localModels {
//            if !availableModels.contains(model),
//               !disabledModels.contains(model) {
//                availableModels.append(model)
//            }
//        }
//        Task {
//            let remoteModels = try await WhisperKit.fetchAvailableModels(from: repoName)
//            for model in remoteModels {
//                if !availableModels.contains(model),
//                   !disabledModels.contains(model) {
//                    availableModels.append(model)
//                }
//            }
//        }
    }
    
    func getDirectorySize(selectedModel: String) -> String {
        var totalSize: Int64 = 0
        
        if localModels.contains(selectedModel) {
            let modelFolder = URL(fileURLWithPath: localModelPath).appendingPathComponent(selectedModel)
            guard let enumerator = FileManager.default.enumerator(at: modelFolder, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]) else {
                print("Failed to create enumerator for \(modelFolder)")
                return "--"
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
        }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        let sizeInBytes = Int(exactly: totalSize) ?? Int.max
        let formattedSize = formatter.string(fromByteCount: Int64(sizeInBytes))
        
        return formattedSize
    }
    
    func getFileCreationDate(for selectedModel: String) -> String? {
        let filePath = URL(fileURLWithPath: localModelPath).appendingPathComponent(selectedModel)
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: filePath.path()),
              let creationDate = attributes[.creationDate] as? Date else {
            return "--"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        
        return formatter.localizedString(for: creationDate, relativeTo: Date())
    }
    
    func deleteModel(selectedModel: String) {
        if localModels.contains(selectedModel) {
            let modelFolder = URL(fileURLWithPath: localModelPath).appendingPathComponent(selectedModel)

            do {
                try FileManager.default.removeItem(at: modelFolder)

                if let index = localModels.firstIndex(of: selectedModel) {
                    localModels.remove(at: index)
                }

                modelState = .unloaded
            } catch {
                print("Error deleting model: \(error)")
            }
        }
    }
    
    func transcribeFile(path: String) {
        resetState()
        whisperKit?.audioProcessor = AudioProcessor()
        self.transcribeTask = Task {
            isTranscribing = true
            do {
                try await transcribeCurrentFile(path: path)
            } catch {
                print("File selection error: \(error.localizedDescription)")
            }
            isTranscribing = false
        }
    }

    func startRecording(_ loop: Bool) {
        if let audioProcessor = whisperKit?.audioProcessor {
            Task(priority: .userInitiated) {
                guard await AudioProcessor.requestRecordPermission() else {
                    print("Microphone access was not granted.")
                    return
                }
                
                var deviceId: DeviceID?
                if self.selectedAudioInput != "None",
                   let devices = self.audioDevices,
                   let device = devices.first(where: { $0.name == selectedAudioInput })
                {
                    deviceId = device.id
                }

                // There is no built-in microphone
                if deviceId == nil {
                    throw WhisperError.microphoneUnavailable()
                }

                try? audioProcessor.startRecordingLive(inputDeviceID: deviceId) { _ in
                    DispatchQueue.main.async { [self] in
                        self.bufferEnergy = self.whisperKit?.audioProcessor.relativeEnergy ?? []
                        bufferSeconds = Double(self.whisperKit?.audioProcessor.audioSamples.count ?? 0) / Double(WhisperKit.sampleRate)
                    }
                }

                // Delay the timer start by 1 second
                isRecording = true
                isTranscribing = true
                if loop {
                    realtimeLoop()
                }
            }
        }
    }

    func stopRecording(_ loop: Bool) {
        isRecording = false
        bufferSeconds = 0
        stopRealtimeTranscription()
        isTranscriptionComplete = false
            
        if let audioProcessor = whisperKit?.audioProcessor {
            audioProcessor.stopRecording()
        }

        if !loop {
            self.transcribeTask = Task {
                isTranscribing = true
                do {
                    try await transcribeCurrentBuffer()
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
                finalizeText()
                isTranscribing = false
            
                await MainActor.run {
                    isTranscriptionComplete = true
                }
            }
        } else {
            finalizeText()
            isTranscriptionComplete = true
        }
    }

    func finalizeText() {
        // Finalize unconfirmed text
        Task {
            await MainActor.run {
                if hypothesisText != "" {
                    confirmedText += hypothesisText
                    hypothesisText = ""
                }

                if unconfirmedSegments.count > 0 {
                    confirmedSegments.append(contentsOf: unconfirmedSegments)
                    unconfirmedSegments = []
                }
            }
        }
    }

    // MARK: - Transcribe Logic

    func transcribeCurrentFile(path: String) async throws {
        // Load and convert buffer in a limited scope
        let audioFileSamples = try await Task {
            try autoreleasepool {
                let audioFileBuffer = try AudioProcessor.loadAudio(fromPath: path)
                return AudioProcessor.convertBufferToArray(buffer: audioFileBuffer)
            }
        }.value

        let transcription = try await transcribeAudioSamples(audioFileSamples)

        await MainActor.run {
            currentText = ""
            guard let segments = transcription?.segments else {
                return
            }

            self.tokensPerSecond = transcription?.timings.tokensPerSecond ?? 0
            self.effectiveRealTimeFactor = transcription?.timings.realTimeFactor ?? 0
            self.effectiveSpeedFactor = transcription?.timings.speedFactor ?? 0
            self.currentEncodingLoops = Int(transcription?.timings.totalEncodingRuns ?? 0)
            self.firstTokenTime = transcription?.timings.firstTokenTime ?? 0
            self.pipelineStart = transcription?.timings.pipelineStart ?? 0
            self.currentLag = transcription?.timings.decodingLoop ?? 0

            self.confirmedSegments = segments
        }
    }

    func transcribeAudioSamples(_ samples: [Float]) async throws -> TranscriptionResult? {
        guard let whisperKit = whisperKit else { return nil }

        let languageCode = Constants.languages[selectedLanguage, default: Constants.defaultLanguageCode]
        let task: DecodingTask = selectedTask == "transcribe" ? .transcribe : .translate
        let seekClip: [Float] = [lastConfirmedSegmentEndSeconds]

        let options = DecodingOptions(
            verbose: true,
            task: task,
            language: languageCode,
            temperature: Float(temperatureStart),
            temperatureFallbackCount: Int(fallbackCount),
            sampleLength: Int(sampleLength),
            usePrefillPrompt: enablePromptPrefill,
            usePrefillCache: enableCachePrefill,
            skipSpecialTokens: !enableSpecialCharacters,
            withoutTimestamps: !enableTimestamps,
            wordTimestamps: true,
            clipTimestamps: seekClip,
            chunkingStrategy: chunkingStrategy
        )

        // Early stopping checks
        let decodingCallback: ((TranscriptionProgress) -> Bool?) = { [self] (progress: TranscriptionProgress) in
            DispatchQueue.main.async {
                let fallbacks = Int(progress.timings.totalDecodingFallbacks)
                let chunkId = self.transcriptionMode == .streaming ? 0 : progress.windowId

                // First check if this is a new window for the same chunk, append if so
                var updatedChunk = (chunkText: [progress.text], fallbacks: fallbacks)
                if var currentChunk = self.currentChunks[chunkId], let previousChunkText = currentChunk.chunkText.last {
                    if progress.text.count >= previousChunkText.count {
                        // This is the same window of an existing chunk, so we just update the last value
                        currentChunk.chunkText[currentChunk.chunkText.endIndex - 1] = progress.text
                        updatedChunk = currentChunk
                    } else {
                        // This is either a new window or a fallback (only in streaming mode)
                        if fallbacks == currentChunk.fallbacks && self.transcriptionMode == .streaming  {
                            // New window (since fallbacks havent changed)
                            updatedChunk.chunkText = [updatedChunk.chunkText.first ?? "" + progress.text]
                        } else {
                            // Fallback, overwrite the previous bad text
                            updatedChunk.chunkText[currentChunk.chunkText.endIndex - 1] = progress.text
                            updatedChunk.fallbacks = fallbacks
                            print("Fallback occured: \(fallbacks)")
                        }
                    }
                }

                // Set the new text for the chunk
                self.currentChunks[chunkId] = updatedChunk
                let joinedChunks = self.currentChunks.sorted { $0.key < $1.key }.flatMap { $0.value.chunkText }.joined(separator: "\n")

                self.currentText = joinedChunks
                self.currentFallbacks = fallbacks
                self.currentDecodingLoops += 1
            }

            // Check early stopping
            let currentTokens = progress.tokens
            let checkWindow = Int(compressionCheckWindow)
            if currentTokens.count > checkWindow {
                let checkTokens: [Int] = currentTokens.suffix(checkWindow)
                let compressionRatio = compressionRatio(of: checkTokens)
                if compressionRatio > options.compressionRatioThreshold! {
                    Logging.debug("Early stopping due to compression threshold")
                    return false
                }
            }
            if progress.avgLogprob! < options.logProbThreshold! {
                Logging.debug("Early stopping due to logprob threshold")
                return false
            }
            return nil
        }

        let transcriptionResults: [TranscriptionResult] = try await whisperKit.transcribe(
            audioArray: samples,
            decodeOptions: options,
            callback: decodingCallback
        )

        let mergedResults = mergeTranscriptionResults(transcriptionResults)

        return mergedResults
    }

    // MARK: Streaming Logic

    func realtimeLoop() {
        transcriptionTask = Task {
            while isRecording && isTranscribing {
                do {
                    try await transcribeCurrentBuffer()
                } catch {
                    print("Error: \(error.localizedDescription)")
                    break
                }
            }
        }
    }

    func stopRealtimeTranscription() {
        isTranscribing = false
        transcriptionTask?.cancel()
    }

    func transcribeCurrentBuffer() async throws {
        guard let whisperKit = whisperKit else { return }

        // Retrieve the current audio buffer from the audio processor
        let currentBuffer = whisperKit.audioProcessor.audioSamples

        // Calculate the size and duration of the next buffer segment
        let nextBufferSize = currentBuffer.count - lastBufferSize
        let nextBufferSeconds = Float(nextBufferSize) / Float(WhisperKit.sampleRate)

        // Only run the transcribe if the next buffer has at least 1 second of audio
        guard nextBufferSeconds > 0.1 else {
            await MainActor.run {
                if currentText == "" {
                    currentText = "Waiting for speech..."
                }
            }
            try await Task.sleep(nanoseconds: 100_000_000) // sleep for 100ms for next buffer
            return
        }

        if useVAD {
            let voiceDetected = AudioProcessor.isVoiceDetected(
                in: whisperKit.audioProcessor.relativeEnergy,
                nextBufferInSeconds: nextBufferSeconds,
                silenceThreshold: Float(silenceThreshold)
            )
            // Only run the transcribe if the next buffer has voice
            guard voiceDetected else {
                await MainActor.run {
                    if currentText == "" {
                        currentText = "Waiting for speech..."
                    }
                }

                // TODO: Implement silence buffer purging
//                if nextBufferSeconds > 30 {
//                    // This is a completely silent segment of 30s, so we can purge the audio and confirm anything pending
//                    lastConfirmedSegmentEndSeconds = 0
//                    whisperKit.audioProcessor.purgeAudioSamples(keepingLast: 2 * WhisperKit.sampleRate) // keep last 2s to include VAD overlap
//                    currentBuffer = whisperKit.audioProcessor.audioSamples
//                    lastBufferSize = 0
//                    confirmedSegments.append(contentsOf: unconfirmedSegments)
//                    unconfirmedSegments = []
//                }

                // Sleep for 100ms and check the next buffer
                try await Task.sleep(nanoseconds: 100_000_000)
                return
            }
        }

        // Store this for next iterations VAD
        lastBufferSize = currentBuffer.count

        if enableEagerDecoding && transcriptionMode == .streaming  {
            // Run realtime transcribe using word timestamps for segmentation
            let transcription = try await transcribeEagerMode(Array(currentBuffer))
            await MainActor.run {
                currentText = ""
                self.tokensPerSecond = transcription?.timings.tokensPerSecond ?? 0
                self.firstTokenTime = transcription?.timings.firstTokenTime ?? 0
                self.pipelineStart = transcription?.timings.pipelineStart ?? 0
                self.currentLag = transcription?.timings.decodingLoop ?? 0
                self.currentEncodingLoops = Int(transcription?.timings.totalEncodingRuns ?? 0)

                let totalAudio = Double(currentBuffer.count) / Double(WhisperKit.sampleRate)
                self.totalInferenceTime = transcription?.timings.fullPipeline ?? 0
                self.effectiveRealTimeFactor = Double(totalInferenceTime) / totalAudio
                self.effectiveSpeedFactor = totalAudio / Double(totalInferenceTime)
            }
        } else {
            // Run realtime transcribe using timestamp tokens directly
            let transcription = try await transcribeAudioSamples(Array(currentBuffer))

            // We need to run this next part on the main thread
            await MainActor.run {
                currentText = ""
                guard let segments = transcription?.segments else {
                    return
                }

                self.tokensPerSecond = transcription?.timings.tokensPerSecond ?? 0
                self.firstTokenTime = transcription?.timings.firstTokenTime ?? 0
                self.pipelineStart = transcription?.timings.pipelineStart ?? 0
                self.currentLag = transcription?.timings.decodingLoop ?? 0
                self.currentEncodingLoops += Int(transcription?.timings.totalEncodingRuns ?? 0)

                let totalAudio = Double(currentBuffer.count) / Double(WhisperKit.sampleRate)
                self.totalInferenceTime += transcription?.timings.fullPipeline ?? 0
                self.effectiveRealTimeFactor = Double(totalInferenceTime) / totalAudio
                self.effectiveSpeedFactor = totalAudio / Double(totalInferenceTime)

                // Logic for moving segments to confirmedSegments
                if segments.count > requiredSegmentsForConfirmation {
                    // Calculate the number of segments to confirm
                    let numberOfSegmentsToConfirm = segments.count - requiredSegmentsForConfirmation

                    // Confirm the required number of segments
                    let confirmedSegmentsArray = Array(segments.prefix(numberOfSegmentsToConfirm))
                    let remainingSegments = Array(segments.suffix(requiredSegmentsForConfirmation))

                    // Update lastConfirmedSegmentEnd based on the last confirmed segment
                    if let lastConfirmedSegment = confirmedSegmentsArray.last, lastConfirmedSegment.end > lastConfirmedSegmentEndSeconds {
                        lastConfirmedSegmentEndSeconds = lastConfirmedSegment.end
                        print("Last confirmed segment end: \(lastConfirmedSegmentEndSeconds)")

                        // Add confirmed segments to the confirmedSegments array
                        for segment in confirmedSegmentsArray {
                            if !self.confirmedSegments.contains(segment: segment) {
                                self.confirmedSegments.append(segment)
                            }
                        }
                    }

                    // Update transcriptions to reflect the remaining segments
                    self.unconfirmedSegments = remainingSegments
                } else {
                    // Handle the case where segments are fewer or equal to required
                    self.unconfirmedSegments = segments
                }
            }
        }
    }

    func transcribeEagerMode(_ samples: [Float]) async throws -> TranscriptionResult? {
        guard let whisperKit = whisperKit else { return nil }

        guard whisperKit.textDecoder.supportsWordTimestamps else {
            confirmedText = "Eager mode requires word timestamps, which are not supported by the current model."
            return nil
        }

        let languageCode = Constants.languages[selectedLanguage, default: Constants.defaultLanguageCode]
        let task: DecodingTask = selectedTask == "transcribe" ? .transcribe : .translate
        print(selectedLanguage)
        print(languageCode)

        let options = DecodingOptions(
            verbose: true,
            task: task,
            language: languageCode,
            temperature: Float(temperatureStart),
            temperatureFallbackCount: Int(fallbackCount),
            sampleLength: Int(sampleLength),
            usePrefillPrompt: enablePromptPrefill,
            usePrefillCache: enableCachePrefill,
            skipSpecialTokens: !enableSpecialCharacters,
            withoutTimestamps: !enableTimestamps,
            wordTimestamps: true, // required for eager mode
            firstTokenLogProbThreshold: -1.5 // higher threshold to prevent fallbacks from running to often
        )

        // Early stopping checks
        let decodingCallback: ((TranscriptionProgress) -> Bool?) = { progress in
            DispatchQueue.main.async {
                let fallbacks = Int(progress.timings.totalDecodingFallbacks)
                if progress.text.count < self.currentText.count {
                    if fallbacks == self.currentFallbacks {
                        //                        self.unconfirmedText.append(currentText)
                    } else {
                        print("Fallback occured: \(fallbacks)")
                    }
                }
                self.currentText = progress.text
                self.currentFallbacks = fallbacks
                self.currentDecodingLoops += 1
            }
            // Check early stopping
            let currentTokens = progress.tokens
            let checkWindow = Int(self.compressionCheckWindow)
            if currentTokens.count > checkWindow {
                let checkTokens: [Int] = currentTokens.suffix(checkWindow)
                let compressionRatio = compressionRatio(of: checkTokens)
                if compressionRatio > options.compressionRatioThreshold! {
                    Logging.debug("Early stopping due to compression threshold")
                    return false
                }
            }
            if progress.avgLogprob! < options.logProbThreshold! {
                Logging.debug("Early stopping due to logprob threshold")
                return false
            }

            return nil
        }

        Logging.info("[EagerMode] \(lastAgreedSeconds)-\(Double(samples.count) / 16000.0) seconds")

        let streamingAudio = samples
        var streamOptions = options
        streamOptions.clipTimestamps = [lastAgreedSeconds]
        let lastAgreedTokens = lastAgreedWords.flatMap { $0.tokens }
        streamOptions.prefixTokens = lastAgreedTokens
        do {
            let transcription: TranscriptionResult? = try await whisperKit.transcribe(audioArray: streamingAudio, decodeOptions: streamOptions, callback: decodingCallback).first
            await MainActor.run {
                var skipAppend = false
                if let result = transcription {
                    hypothesisWords = result.allWords.filter { $0.start >= lastAgreedSeconds }

                    if let prevResult = prevResult {
                        prevWords = prevResult.allWords.filter { $0.start >= lastAgreedSeconds }
                        let commonPrefix = findLongestCommonPrefix(prevWords, hypothesisWords)
                        Logging.info("[EagerMode] Prev \"\((prevWords.map { $0.word }).joined())\"")
                        Logging.info("[EagerMode] Next \"\((hypothesisWords.map { $0.word }).joined())\"")
                        Logging.info("[EagerMode] Found common prefix \"\((commonPrefix.map { $0.word }).joined())\"")

                        if commonPrefix.count >= Int(tokenConfirmationsNeeded) {
                            lastAgreedWords = commonPrefix.suffix(Int(tokenConfirmationsNeeded))
                            lastAgreedSeconds = lastAgreedWords.first!.start
                            Logging.info("[EagerMode] Found new last agreed word \"\(lastAgreedWords.first!.word)\" at \(lastAgreedSeconds) seconds")

                            confirmedWords.append(contentsOf: commonPrefix.prefix(commonPrefix.count - Int(tokenConfirmationsNeeded)))
                            let currentWords = confirmedWords.map { $0.word }.joined()
                            Logging.info("[EagerMode] Current:  \(lastAgreedSeconds) -> \(Double(samples.count) / 16000.0) \(currentWords)")
                        } else {
                            Logging.info("[EagerMode] Using same last agreed time \(lastAgreedSeconds)")
                            skipAppend = true
                        }
                    }
                    prevResult = result
                }

                if !skipAppend {
                    eagerResults.append(transcription)
                }
            }

            await MainActor.run {
                let finalWords = confirmedWords.map { $0.word }.joined()
                confirmedText = finalWords

                // Accept the final hypothesis because it is the last of the available audio
                let lastHypothesis = lastAgreedWords + findLongestDifferentSuffix(prevWords, hypothesisWords)
                hypothesisText = lastHypothesis.map { $0.word }.joined()
            }
        } catch {
            Logging.error("[EagerMode] Error: \(error)")
            finalizeText()
        }


        let mergedResult = mergeTranscriptionResults(eagerResults, confirmedWords: confirmedWords)

        return mergedResult
    }
    
    
    // Transcription methods
    public func getFullTranscript() -> String {
        print("Getting full transcript")

        let segments = confirmedSegments + unconfirmedSegments
        let transcript = formatSegments(segments, withTimestamps: false)
        return transcript.joined(separator: "\n")
    }
}
