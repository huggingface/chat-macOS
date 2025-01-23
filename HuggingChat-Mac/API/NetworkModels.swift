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
    let webSearch: MessageWebSearch?
    //    let updates: [Update]

    private enum CodingKeys: String, CodingKey {
        case id, content
        case author = "from"
        case createdAt, updatedAt, webSearch
    }

    init(id: String, content: String, author: Author, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.content = content
        self.author = author
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.webSearch = nil
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
        self.webSearch = try container.decodeIfPresent(MessageWebSearch.self, forKey: .webSearch)
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
    let type: String
    let status, text: String?
}

struct MessageWebSearch: Decodable {
    let prompt: String
    let contextSources: [WebSearchSource]
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
