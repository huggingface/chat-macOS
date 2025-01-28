//
//  NetworkModels.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/22/25.
//

import Foundation
import Combine

final class LoginChat: Codable {
    var type: String
    var location: String
    var status: Int
}

/// HuggingChat user struct responsible for holding user information
struct HuggingChatUser: Decodable, Equatable {
    let id: String
    let username: String
    let email: String
    let avatarUrl: URL
    let hfUserId: String
    
    enum CodingKeys: CodingKey {
        case id
        case username
        case email
        case avatarUrl
        case hfUserId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.username = try container.decode(String.self, forKey: .username)
        self.email = (try? container.decode(String.self, forKey: .email)) ?? ""
        self.avatarUrl = (try? container.decode(URL.self, forKey: .avatarUrl)) ?? URL(string: "https://google.fr")!
        self.hfUserId = try container.decode(String.self, forKey: .hfUserId)
    }
    
    init(id: String, username: String, email: String, avatarUrl: URL, hfUserId: String) {
        self.id = id
        self.username = username
        self.email = email
        self.avatarUrl = avatarUrl
        self.hfUserId = hfUserId
    }
}

// Conversation model received from the server
protocol BaseConversation {
    var id: String { get }
    func toNewConversation() -> (AnyObject&Codable)
}

struct NewConversation: Decodable {
    let id: String

    enum CodingKeys: String, CodingKey {
        case id = "conversationId"
    }
}

// Used to edit conversation title
struct TitleEditionBody: Encodable {
    let title: String
}

// Used to share conversation
struct SharedConversation: Decodable {
    let url: URL
}

final class Conversation: Decodable, Identifiable, Hashable {
    let id = UUID()
    let serverId: String
    var title: String
    let modelId: String
    let updatedAt: Date
    var messages: [Message] = []

    init(
        serverId: String, title: String, modelId: String, updatedAt: Date, messages: [Message] = []
    ) {
        self.serverId = serverId
        self.title = title
        self.modelId = modelId
        self.updatedAt = updatedAt
        self.messages = messages
    }

    enum CodingKeys: CodingKey {
        case id
        case title
        case modelId
        case updatedAt
        case messages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.serverId = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.modelId = try container.decode(String.self, forKey: .modelId)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        do {
            let messages = try container.decode([Message].self, forKey: .messages)
            self.messages = messages
        } catch {
            self.messages = []
        }
    }
    
    func toTitleEditionBody() -> TitleEditionBody {
        return TitleEditionBody(title: title)
    }
    
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
       lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
       hasher.combine(id)
    }
}

enum Author: String, Decodable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}

// MARK: - Message
final class Message: Decodable, Identifiable, Hashable {
    let id: String
    var content: String
    let author: Author
    let createdAt: Date
    let updatedAt: Date
    let updates: [Update]?
    let files: [String]?
    let reasoning: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, content
        case author = "from"
        case createdAt, updatedAt, updates, files, reasoning
    }

    init(id: String, content: String, author: Author, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.content = content
        self.author = author
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.updates = nil
        self.files = nil
        self.reasoning = nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.content = try container.decode(String.self, forKey: .content)
        if let author = try? container.decode(String.self, forKey: .author) {
            self.author = Author(rawValue: author) ?? .assistant
        } else {
            self.author = .assistant
        }
        
        let updatedAt = (try? container.decode(Date.self, forKey: .updatedAt)) ?? Date()
        self.updatedAt = updatedAt
        self.createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? updatedAt
        self.updates = try? container.decodeIfPresent([Update].self, forKey: .updates)
        self.files = try? container.decodeIfPresent([String].self, forKey: .files)
        self.reasoning = try? container.decodeIfPresent(String.self, forKey: .reasoning)
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
       lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
       hasher.combine(id)
    }
}

// MARK: - Update
struct Update: Decodable {
    let type: UpdateType
    let subtype: String?
    let status: String?
    let message: String?
    let title: String?
    let text: String?
    let args: [String]?
    let sources: [WebSearchSource]?
    let interrupted: Bool?
    let webSources: [WebSearchSource]? // Potentially deprecated? Do not use
    
    private enum CodingKeys: String, CodingKey {
        case type, subtype, status, message, title, text, args, sources
        case interrupted, webSources
    }
}

enum UpdateType: String, Decodable {
    case status
    case webSearch
    case title
    case reasoning
    case finalAnswer
    case unknown
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = UpdateType(rawValue: rawValue) ?? .unknown
    }
}

struct WebSearchSource: Identifiable, Decodable {
    var id = UUID()
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
    
    // Convenience Init
    init(link: URL, title: String, hostname: String) {
        self.link = link
        self.title = title
        self.hostname = hostname
    }
}

// MARK: LLM Model
struct PromptExample: Codable {
    let title: String
    let prompt: String
}

final class NewConversationFromModelRequestBody: Codable {
    let model: String
    let preprompt: String
    
    init(model: String, preprompt: String) {
        self.model = model
        self.preprompt = preprompt
    }
}


final class LLMModel: Codable, Identifiable, Hashable, BaseConversation {
    let id: String
    let name: String
    let displayName: String
    let websiteUrl: URL
    let modelUrl: URL
    let tools: Bool
    let promptExamples: [PromptExample]
    let multimodal: Bool
    let unlisted: Bool
    let description: String
    var preprompt: String

    init(
        id: String, name: String, displayName: String, websiteUrl: URL, modelUrl: URL,
        promptExamples: [PromptExample], multimodal: Bool, unlisted: Bool, description: String,
        isActive: Bool, preprompt: String, tools: Bool
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.websiteUrl = websiteUrl
        self.modelUrl = modelUrl
        self.promptExamples = promptExamples
        self.multimodal = multimodal
        self.unlisted = unlisted
        self.description = description
        self.preprompt = preprompt
        self.tools = tools
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.displayName = try container.decode(String.self, forKey: .displayName)

        if let url = try? container.decode(URL.self, forKey: .websiteUrl) {
            self.websiteUrl = url
        } else {
            self.websiteUrl = URL(string: "https://huggingface.co/\(self.name)")!
        }
        
        if let url = try? container.decode(URL.self, forKey: .modelUrl) {
            self.modelUrl = url
        } else {
            self.modelUrl = URL(string: "https://huggingface.co/\(self.name)")!
        }

        self.promptExamples = (try? container.decode([PromptExample].self, forKey: .promptExamples)) ?? []
        
        self.multimodal = try container.decode(Bool.self, forKey: .multimodal)
        self.unlisted = try container.decode(Bool.self, forKey: .unlisted)
        self.description = (try? container.decode(String.self, forKey: .description)) ?? ""

        self.preprompt = try container.decode(String.self, forKey: .preprompt)
        self.tools = try container.decode(Bool.self, forKey: .tools)
    }
    
    static func == (lhs: LLMModel, rhs: LLMModel) -> Bool {
       lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
       hasher.combine(id)
    }
    
    func toNewConversation() -> (AnyObject&Codable) {
        return NewConversationFromModelRequestBody(model: id, preprompt: preprompt)
    }

}

// Streaming options
struct PromptRequestBody: Encodable {
    let id: String?
    var files: [String]? = nil
    let inputs: String?
    let isRetry: Bool?
    let isContinue: Bool?
    let webSearch: Bool?
    let tools: [String]?
    
    init(id: String? = nil, inputs: String? = nil, isRetry: Bool = false, isContinue: Bool = false, webSearch: Bool = false, files: [String]? = nil, tools: [String]? = nil) {
        self.id = id
        self.inputs = inputs
        self.isRetry = isRetry
        self.isContinue = isContinue
        self.webSearch = webSearch
        self.files = files
        self.tools = tools
    }
}

struct FileMessage: Decodable {
    let name: String
    let sha: String
    let mime: String
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
        case reasoning
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

enum StreamReasoning {
    case status(String)
    case stream(String)
}

enum StreamMessageType {
    case started
    case token(String)
    case webSearch(StreamWebSearch)
    case reasoning(StreamReasoning)
    case skip
    
    static func messageType(from json: StreamMessage) -> StreamMessageType? {
#if DEBUG
        print("🔥", json.type, json)
#endif
        switch json.type {
        case "webSearch":
            return webSearch(from: json)
        case "reasoning":
            return reasoning(from: json)
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
    
    private static func reasoning(from json: StreamMessage) -> StreamMessageType? {
            guard let subtype = json.subtype else { return nil }
            
            switch subtype {
            case "status":
                return .reasoning(.status(json.message ?? "Thinking"))
            case "stream":
                return .reasoning(.stream(json.token ?? ""))
            default:
                return nil
            }
        }
}

final class SendPromptHandler {
    
    private static let throttleTime: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(100)
    private var privateUpdate: PassthroughSubject<StreamMessageType, HFError> = PassthroughSubject<
        StreamMessageType, HFError
    >()
    
    private let conversationId: String
    private var cancellables: [AnyCancellable] = []
    private var postPrompt: PostStream? = PostStream()
    private var currentMessage: MessageViewModel
    
    var update: AnyPublisher<MessageViewModel, HFError> {
        return privateUpdate
            .map({ [weak self] (messageType: StreamMessageType) -> MessageViewModel? in
                guard let self else { fatalError() }
                self.updateMessage(with: messageType)
                return self.currentMessage
            })
            .compactMap({ $0 })
            .throttle(
                for: SendPromptHandler.throttleTime, scheduler: DispatchQueue.main, latest: true
            ).eraseToAnyPublisher()
    }
    
    init(conversationId: String, messageVM: MessageViewModel) {
        self.conversationId = conversationId
        self.currentMessage = messageVM
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
    
    private func updateMessage(with message: StreamMessageType) {
        switch message {
        case .token(let token):
            currentMessage.content += token
        case .started:
            break
        case .webSearch(let update):
            switch update {
            case .message(let message):
                if currentMessage.isBrowsingWeb == false {
                    currentMessage.isBrowsingWeb = true
                }
                currentMessage.webSearchUpdates.append(message)
            case .sources(let sources):
                currentMessage.isBrowsingWeb = false
                currentMessage.webSources = sources
            }
        case .reasoning(let reasoning):
            switch reasoning {
            case .status(let status):
                currentMessage.reasoningUpdates.append(status)
            case .stream(let token):
                if let _ = currentMessage.reasoning {
                    currentMessage.reasoning! += token
                } else {
                    currentMessage.reasoning = token
                }
                
//                // For stream updates, we might want to append to the last update
//                // or create a new one depending on your needs
//                if token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//                    return
//                }
//                
//                if let lastUpdate = currentMessage.reasoningUpdates.last {
//                    currentMessage.reasoningUpdates[currentMessage.reasoningUpdates.count - 1] = lastUpdate + token
//                } else {
//                    currentMessage.reasoningUpdates.append(token)
//                }
            }
        case .skip:
            break
        }
    }
}
