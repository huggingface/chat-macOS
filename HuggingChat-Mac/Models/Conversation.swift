//
//  Conversation.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/23/24.
//

import Combine
import Foundation

final class Conversation: Decodable, Identifiable {
    let id = UUID()
    let serverId: String
    var title: String
    let modelId: String
    let updatedAt: Date
    var messages: [Message]
    var areMessagesLoaded: Bool
    var assistantId: String?

    init(
        serverId: String, title: String, modelId: String, updatedAt: Date, messages: [Message],
        areMessagesLoaded: Bool, assistantId: String? = nil
    ) {
        self.serverId = serverId
        self.title = title
        self.modelId = modelId
        self.updatedAt = updatedAt
        self.messages = messages
        self.areMessagesLoaded = areMessagesLoaded
        self.assistantId = assistantId
    }

    enum CodingKeys: CodingKey {
        case id
        case title
        case modelId
        case updatedAt
        case messages
        case areMessagesLoaded
        case assistantId
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
            self.areMessagesLoaded = true
        } catch {
            //ToDo: Handle Error
//            print("error: \(error)")
            self.messages = []
            self.areMessagesLoaded = false
        }
        
        self.assistantId = try container.decodeIfPresent(String.self, forKey: .assistantId)
    }

    func loadMessages() -> AnyPublisher<[Message], HFError> {
        return NetworkService.getConversation(id: serverId).map { [weak self] conv in
            self?.messages = conv.messages
            return conv.messages
        }.eraseToAnyPublisher()
    }

    static func conversation(with id: String) -> Conversation {
        return Conversation(
            serverId: id, title: "Blahblahbla", modelId: "", updatedAt: Date(), messages: [],
            areMessagesLoaded: false)
    }

    static func conversation(title: String, updatedAt: Date) -> Conversation {
        return Conversation(
            serverId: UUID().uuidString, title: title, modelId: "model", updatedAt: updatedAt,
            messages: [], areMessagesLoaded: false)
    }
    
    func toTitleEditionBody() -> TitleEditionBody {
        return TitleEditionBody(title: title)
    }
    
    func isFirstMessageSystem() -> Bool {
        if case .system = messages.first?.author {
            return true
        }
        
        return false
    }
//
//    func areMessagesConsistent(with rMessages: [MessageRow]) -> Bool {
//        var rIDs = rMessages.map { $0.id }
//        let mIDs = messages.map { $0.id }.dropFirst()
//
//        return rIDs == mIDs
//    }
}

extension Conversation {

}

