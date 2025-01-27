//
//  ViewModels.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/24/25.
//

import Foundation


// View Models
@Observable
class MessageViewModel: Identifiable, Hashable {
    let id: String
    var content: String
    let author: Author
    var webSources: [WebSearchSource]?
    let files: [String]?
    let reasoning: String?
    
    var isBrowsingWeb: Bool = false
    var webSearchUpdates: [String] = []
    
    // Updates
    var reasoningUpdates: [String] = []
    
    
    init(author: Author, content: String, files: [String]? = nil) {
        self.id = UUID().uuidString.lowercased()
        self.author = author
        self.content = content
        self.webSources = nil
        self.files = files
        self.reasoning = nil
    }
    
    // Convenience init
    init?(message: Message) {
        self.id = message.id
        self.content = message.content
        self.author = message.author
        self.files = message.files
        self.reasoning = message.reasoning
        
        // Initialize webSources to nil initially
        self.webSources = nil
        
        // Extract web sources from updates
        if let updates = message.updates {
            for update in updates {
                if update.type == .reasoning,
                   update.subtype == "status",
                   let status = update.status {
                    reasoningUpdates.append(status)
                }
                if update.type == .webSearch, update.subtype == "update", let webUpdate = update.message {
                    webSearchUpdates.append(webUpdate)
                }
            }
            
            // Update webSources if matching updates are found
            if let webSourceUpdate = updates.first(where: { update in
                update.type == .webSearch &&
                update.subtype == "sources" &&
                update.message == "sources"
            })?.sources {
                self.webSources = webSourceUpdate
            }
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
    var websiteUrl: URL
    var modelUrl: URL
    var promptExamples: [PromptExample]
    var multimodal: Bool
    var unlisted: Bool
    var description: String
    var preprompt: String
    var tools: Bool
    
    init(model: LLMModel) {
        self.id = model.id
        self.name = model.name
        self.displayName = model.displayName
        self.websiteUrl = model.websiteUrl
        self.modelUrl = model.modelUrl
        self.promptExamples = model.promptExamples
        self.multimodal = model.multimodal
        self.unlisted = model.unlisted
        self.description = model.description
        self.preprompt = model.preprompt
        self.tools = model.tools
    }
    
    static func == (lhs: LLMViewModel, rhs: LLMViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func toLLMModel() -> LLMModel {
            return LLMModel(
                id: self.id,
                name: self.name,
                displayName: self.displayName,
                websiteUrl: self.websiteUrl,
                modelUrl: self.modelUrl,
                promptExamples: self.promptExamples,
                multimodal: self.multimodal,
                unlisted: self.unlisted,
                description: self.description,
                isActive: true,
                preprompt: self.preprompt,
                tools: self.tools
            )
        }
}
