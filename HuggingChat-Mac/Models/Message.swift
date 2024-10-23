//
//  Message.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/23/24.
//

import Combine
import Foundation

enum Author: String, Decodable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}

// MARK: - Message
final class Message: Decodable {
    var contentHeight: CGFloat = 50
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
        //        , updates
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
