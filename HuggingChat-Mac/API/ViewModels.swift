//
//  ViewModels.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/24/25.
//

import Foundation


// View Models
struct MessageViewModel: Identifiable, Hashable {
    let id: String
    var content: String
    let author: Author
    let webSources: [WebSearchSource]?
    let files: [String]?
    let reasoning: String?
    
    // Updates
    var reasoningUpdates: [String] = []
    var webSearchUpdates: [String] = []
    
    init(message: Message) {
        self.id = message.id
        self.content = message.content
        self.author = message.author
        self.files = message.files
        self.reasoning = message.reasoning
        
        // Extract web sources from updates
        if let updates = message.updates {
            for update in updates {
                if update.type == .reasoning,
                   update.subtype == "status",
                   let status = update.status {
                    reasoningUpdates.append(status)
                }
                if update.type == .webSearch,  update.subtype == "update", let webUpdate = update.message {
                    webSearchUpdates.append(webUpdate)
                }
            }
            self.webSources = updates.first { update in
                update.type == .webSearch &&
                update.subtype == "sources" &&
                update.message == "sources"
            }?.sources
        } else {
            self.webSources = nil
        }
    }
    
    static func == (lhs: MessageViewModel, rhs: MessageViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct LLMViewModel: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var displayName: String
    var multimodal: Bool
    var description: String
    
    init(model: LLMModel) {
        self.id = model.id
        self.name = model.name
        self.displayName = model.displayName
        self.multimodal = model.multimodal
        self.description = model.description
    }
    
    static func == (lhs: LLMViewModel, rhs: LLMViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
