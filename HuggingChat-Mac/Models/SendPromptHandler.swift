//
//  SendPromptHandler.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/29/24.
//

import Combine
import SwiftUI
import Foundation
import AppKit

extension NSFont {
    func apply(newTraits: NSFontDescriptor.SymbolicTraits, newPointSize: CGFloat? = nil) -> NSFont {
        var existingTraits = fontDescriptor.symbolicTraits
        existingTraits.insert(newTraits)
        
        let newFontDescriptor = fontDescriptor.withSymbolicTraits(existingTraits)
        if let newFont = NSFont(descriptor: newFontDescriptor, size: newPointSize ?? pointSize) {
            return newFont
        } else {
            return self
        }
    }
}

struct StreamMessage: Decodable {
    let type: String
    let token: String?
    let subtype: String?
    let message: String?
    let sources: [WebSearchSource]?
    
    enum CodingKeys: CodingKey {
        case type
        case token
        case subtype
        case message
        case sources
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.token = try container.decodeIfPresent(String.self, forKey: .token)?.trimmingCharacters(in: .nulls) ?? ""
        self.subtype = try container.decodeIfPresent(String.self, forKey: .subtype)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
        self.sources = try container.decodeIfPresent([WebSearchSource].self, forKey: .sources)
    }
}

struct WebSearchSource: Decodable {
    let link: URL
    let title: String
    let hostname: String
    
    enum CodingKeys: CodingKey {
        case link
        case title
        case hostname
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.link = try container.decode(URL.self, forKey: .link)
        self.title = try container.decode(String.self, forKey: .title)
        do {
            self.hostname = (try container.decode(String.self, forKey: .hostname)).deletingPrefix("www.")
        } catch {
            self.hostname = link.host?.deletingPrefix("www.") ?? link.absoluteString.deletingPrefix("www.")
        }
    }
}

final class WebSearch {
    var message: String
    var sources: [WebSearchSource]
    
    init(message: String, sources: [WebSearchSource]) {
        self.message = message
        self.sources = sources
    }
}

enum StreamWebSearch {
    case message(String)
    case sources([WebSearchSource])
}

enum StreamMessageType {
    case started
    case token(String)
    case webSearch(StreamWebSearch)
    case skip
    
    static func messageType(from json: StreamMessage) -> StreamMessageType? {
        switch json.type {
        case "webSearch":
            return webSearch(from: json)
        case "stream":
            return .token(json.token ?? "")
        case "title":
            return .skip
        default:
            return .skip
        }
    }
    
    private static func webSearch(from json: StreamMessage) -> StreamMessageType? {
        guard let messageType = json.subtype else { return nil }
        
        switch messageType {
        case "sources":
            return .webSearch(.sources(json.sources ?? []))
        case "update":
            return .webSearch(.message(json.message ?? ""))
        default:
            return nil
        }
    }
}

final class SendPromptHandler {
    
    var isDarkMode: Bool {
        guard let window = NSApp.keyWindow else {
            return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
        return window.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    private static let throttleTime: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(100)
    private var privateUpdate: PassthroughSubject<StreamMessageType, HFError> = PassthroughSubject<
        StreamMessageType, HFError
    >()

    private var responseMessage: String = ""
    private var currentTextCount: Int = 0
    private let conversationId: String

    private let parserThresholdTextCount = 0
    private var currentOutput: AttributedOutput?
    
    private var cancellables: [AnyCancellable] = []

    var messageRow: MessageRow
    
    private var postPrompt: PostStream? = PostStream()

    var update: AnyPublisher<MessageRow, HFError> {
        return privateUpdate
            .map({ [weak self] (messageType: StreamMessageType) -> MessageRow? in
                guard let self else { fatalError() }
                return self.updateMessageRow(with: messageType)
            })
            .compactMap({  $0 })
            .eraseToAnyPublisher()
//            .throttle(
//                for: SendPromptHandler.throttleTime, scheduler: DispatchQueue.main, latest: true
//            ).eraseToAnyPublisher()
    }

    init(conversationId: String) {
        self.conversationId = conversationId
        self.messageRow = MessageRow(
            type: .assistant, isInteracting: true, contentType: .rawText(" "))
    }
    
    var tmpMessage: String = ""
    
    private let decoder: JSONDecoder = JSONDecoder()
    
    func sendPromptReq(reqBody: PromptRequestBody) {
        postPrompt?.postPrompt(reqBody: reqBody, conversationId: conversationId).sink(receiveCompletion: { [weak self] completion in
            switch completion {
            case .finished:
                self?.privateUpdate.send(completion: .finished)
            case .failure(let error):
                print("error \(error)")
                self?.privateUpdate.send(completion: .failure(error))
            }
        }, receiveValue: { [weak self] (data: Data) in
            guard let self = self, let message = String(data: data, encoding: .utf8) else {
                return
            }
            let messages = message.split(separator: "\n")
            for m in messages {
                self.tmpMessage = self.tmpMessage + m
                guard let sd = self.tmpMessage.data(using: .utf8) else {
                    continue
                }
                guard let json = try? self.decoder.decode(StreamMessage.self, from: sd) else {
                    continue
                }
                self.tmpMessage = ""
                self.privateUpdate.send(StreamMessageType.messageType(from: json) ?? .skip)
            }
        }).store(in: &cancellables)
    }

    lazy var parsingTask = ResponseParsingTask(isDarkMode: isDarkMode)
    var attributedSend: AttributedOutput = AttributedOutput(string: "", results: [])

    private func updateMessageRow(with message: StreamMessageType) -> MessageRow? {
        switch message {
        case .started:
            return messageRow
        case .webSearch(let update):
            if messageRow.webSearch == nil {
                messageRow.webSearch = WebSearch(message: "", sources: [])
            }
            switch update {
            case .message(let message):
                messageRow.webSearch?.message = message
            case .sources(let sources):
                messageRow.webSearch?.sources = sources
            }
            return messageRow
        case .token(let token):
            messageRow.webSearch?.message = "Completed"
            return updateMessage(with: token)
        case .skip:
            return nil
        }
    }
    
    private func updateMessage(with token: String) -> MessageRow {
        attributedSend = parsingTask.parse(text: token)
        responseMessage += token
        currentTextCount += token.count

        if currentTextCount >= parserThresholdTextCount || token.contains("```") {
            currentOutput = parsingTask.parse(text: responseMessage)
            currentTextCount = 0
        }

        if let currentOutput = currentOutput, !currentOutput.results.isEmpty {
            let suffixText = responseMessage.deletingPrefix(currentOutput.string)
            var results = currentOutput.results
            let lastResult = results[results.count - 1]
            let lastAttrString = lastResult.attributedString
            if case .codeBlock(_) = lastResult.resultType {
                lastAttrString.append(
                    NSMutableAttributedString(string:
                                            String(suffixText),
                                            attributes: .init([
                                                .font: NSFont.systemFont(ofSize: 12).apply(newTraits: .monoSpace),
                                                .foregroundColor: NSColor.white,
                                            ])))
            } else {
                lastAttrString.append(NSMutableAttributedString(string: String(suffixText)))
            }
            results[results.count - 1] = ParserResult(
                attributedString: lastAttrString, resultType: lastResult.resultType)
            messageRow.contentType = .attributed(.init(string: responseMessage, results: results))
        } else {
            messageRow.contentType = .attributed(
                .init(
                    string: responseMessage,
                    results: [
                        ParserResult(
                            attributedString: NSMutableAttributedString(string: responseMessage),
                            resultType: .text)
                    ]))
        }

        if let currentString = currentOutput?.string, currentString != responseMessage {
            let output = parsingTask.parse(text: responseMessage)
            messageRow.contentType = .attributed(output)
        }

        return messageRow
    }
    
    func cancel() {
        cancellables = []
        postPrompt = nil
    }

}


