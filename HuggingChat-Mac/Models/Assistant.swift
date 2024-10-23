//
//  Assistant.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/23/24.
//

import Foundation

final class Assistant: Decodable, Identifiable, BaseConversation {
    
    let id: String
    let creatorID: String?
    let createdByMe: Bool?
    let creatorName: String
    let name: String
    let modelID: String
    var preprompt: String
    let description: String
    let promptExamples: [PromptExample]
    let avatarID: String?
    let createdAt: Date
    let updatedAt: Date
    let userCount: Int
    let featured: Bool
    let searchTokens: [String]

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case creatorID = "createdById"
        case creatorName = "createdByName"
        case name
        case modelID = "modelId"
        case avatarID = "avatar"
        case preprompt, description, exampleInputs, createdAt, updatedAt, userCount, featured, searchTokens, createdByMe
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        if let creatorID = try? container.decode(String.self, forKey: .creatorID) {
            self.creatorID = creatorID
            self.createdByMe = nil
        } else if let createdByMe = try? container.decode(Bool.self, forKey: .createdByMe) {
            self.creatorID = nil
            self.createdByMe = createdByMe
        } else {
            throw HFError.decodeError(HFError.unknown)
        }
        self.creatorName = try container.decode(String.self, forKey: .creatorName)
        self.name = try container.decode(String.self, forKey: .name)
        self.modelID = try container.decode(String.self, forKey: .modelID)
        self.avatarID = try container.decodeIfPresent(String.self, forKey: .avatarID)
        self.preprompt = try container.decode(String.self, forKey: .preprompt)
        self.description = try container.decode(String.self, forKey: .description)
        if let inputs = try? container.decode([String].self, forKey: .exampleInputs) {
            self.promptExamples = inputs.map { PromptExample(title: $0, prompt: $0) }
        } else {
            self.promptExamples = []
        }
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.userCount = try container.decode(Int.self, forKey: .userCount)
        self.featured = try container.decode(Bool.self, forKey: .featured)
        self.searchTokens = try container.decode([String].self, forKey: .searchTokens)
    }
    
    func toNewConversation() -> (AnyObject&Codable) {
        return NewConversationFromAssistantRequestBody(model: modelID, assistantId: id)
    }
}

struct AssistantResponse: Decodable {
    let assistants: [Assistant]
    let numTotalItems: Int
    let numItemsPerPage: Int
}

