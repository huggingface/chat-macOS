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
    
    init(message: Message) {
        self.id = message.id
        self.content = message.content
        self.author = message.author
        self.files = message.files
        
        // Extract web sources from updates
        if let updates = message.updates {
            self.webSources = updates.first { update in
                update.type == .webSearch &&
                update.subtype == "sources" &&
                update.message == "sources"
            }?.sources
        } else {
            self.webSources = nil
        }
    }
    
    // Required for Hashable
    static func == (lhs: MessageViewModel, rhs: MessageViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
