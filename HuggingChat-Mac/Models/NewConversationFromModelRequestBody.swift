//
//  NewConversationFromModelRequestBody.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/23/24.
//

import Foundation

final class NewConversationFromModelRequestBody: Codable {
    let model: String
    let preprompt: String
    
    init(model: String, preprompt: String) {
        self.model = model
        self.preprompt = preprompt
    }
}

final class NewConversationFromAssistantRequestBody: Codable {
    let model: String
    let assistantId: String
    
    init(model: String, assistantId: String) {
        self.model = model
        self.assistantId = assistantId
    }
}
