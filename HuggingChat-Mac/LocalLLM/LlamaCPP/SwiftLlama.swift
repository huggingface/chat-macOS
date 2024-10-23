//
//  SwiftLlama.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 10/2/24.
//

import Foundation
import llama
import Combine

public class SwiftLlama {
    private let model: LlamaModel
    private let configuration: LlamaConfiguration
    private var contentStarted = false

    private lazy var resultSubject: CurrentValueSubject<String, Error> = {
        .init("")
    }()
    private var generatedTokenCache = ""
    
    var history: [LlamaChatMessage] = []

    var maxLengthOfStopToken: Int {
        model.eogTokens.map { $0.count }.max() ?? 0
    }
    
    private var generationTask: Task<Void, Error>?

    public init(modelPath: String,
                 modelConfiguration: LlamaConfiguration = .init()) throws {
        self.model = try LlamaModel(path: modelPath, configuration: modelConfiguration)
        self.configuration = modelConfiguration
        self.history.append(LlamaChatMessage(role: "system", content: "You are a helpful assistant."))
    }
    
    private func prepareHistory(with prompt:String) -> String {
        history.append(LlamaChatMessage(role: "user", content: prompt))
        if let templatedChats = model.apply_chat_template(template: nil, chat: history, addAss: true) {
            return templatedChats
        } else {
            // In case template errors, just return the prompt. Should likely not happen.
            return prompt
        }
    }
    
    func logResponse(for response: String) {
        history.append(LlamaChatMessage(role: "system", content: response))
    }

    private func response(for prompt: String, output: (String) -> Void, finish: () -> Void) throws {
        func finalizeOutput() {
            model.eogTokens.forEach {
                generatedTokenCache = generatedTokenCache.replacingOccurrences(of: $0, with: "")
            }
            output(generatedTokenCache)
            finish()
            generatedTokenCache = ""
        }
        defer {
            model.clear()
        }
        do {
            try model.start(for: prompt)
            while model.shouldContinue {
                if Task.isCancelled {
                    model.clear()
                    break
                }
                
                var delta = try model.continue()
                if contentStarted {
                    if needToStop(after: delta, output: output) {
                        break
                    }
                } else {
                    delta = delta.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !delta.isEmpty {
                        contentStarted = true
                        if needToStop(after: delta, output: output) {
                            break
                        }
                    }
                }
                
                try Task.checkCancellation()
            }
            finalizeOutput()
        } catch {
            throw error
        }
    }

    public func cancelGeneration() {
        generationTask?.cancel()
        _ = history.popLast()
        generatedTokenCache = ""
    }

    @LlamaActor
    public func start(for prompt: String) -> AsyncThrowingStream<String, Error> {
        print("SwiftLlama: Entering start(for:) - AsyncThrowingStream")
        let fixedPrompt = prepareHistory(with: prompt)
        return AsyncThrowingStream { continuation in
            generationTask = Task {
                do {
                    print("SwiftLlama: Beginning generation task")
                    try Task.checkCancellation()
                    try response(for: fixedPrompt) { delta in
                        continuation.yield(delta)
                    } finish: {
                        print("SwiftLlama: Finished generation")
                        continuation.finish()
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    @LlamaActor
    public func start(for prompt: String) -> AnyPublisher<String, Error> {
        print("SwiftLlama: Entering start(for:) - AnyPublisher")
        let fixedPrompt = prepareHistory(with: prompt)
        generationTask = Task {
            do {
                print("SwiftLlama: Beginning generation task")
                try Task.checkCancellation()
                try response(for: fixedPrompt) { delta in
                    resultSubject.send(delta)
                } finish: {
                    print("SwiftLlama: Finished generation")
                    resultSubject.send(completion: .finished)
                }
            } catch {
                resultSubject.send(completion: .failure(error))
            }
        }
        return resultSubject.eraseToAnyPublisher()
    }
    
    @LlamaActor
    public func start(for prompt: String) async throws -> String {
        let fixedPrompt = prepareHistory(with: prompt)
        
        var result = ""
        do {
            for try await value in start(for: fixedPrompt) {
                result += value
            }
        } catch {
            print("[2] Error occurred: \(error)")
            throw error  // Propagate the error
        }
        return result
    }
    
    public func clearSession() {
        history = [LlamaChatMessage(role: "system", content: "You are a helpful assistant.")]
        model.clear()
        cancelGeneration()
    }

    /// Handling logic of StopToken
    private func needToStop(after delta: String, output: (String) -> Void) -> Bool {
        guard maxLengthOfStopToken > 0 else {
            output(delta)
            return false
        }
        generatedTokenCache += delta
        if generatedTokenCache.count >= maxLengthOfStopToken * 2 {
            if let stopToken = model.eogTokens.first(where: { generatedTokenCache.contains($0) }),
               let index = generatedTokenCache.range(of: stopToken) {
                let outputCandidate = String(generatedTokenCache[..<index.lowerBound])
                output(outputCandidate)
                generatedTokenCache = ""
                return true
            } else { // no stop token generated
                let outputCandidate = String(generatedTokenCache.prefix(maxLengthOfStopToken))
                generatedTokenCache.removeFirst(outputCandidate.count)
                output(outputCandidate)
                return false
            }
        }
        return false
    }
}

