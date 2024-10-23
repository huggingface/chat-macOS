//
//  NewConversation.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/23/24.
//

import Foundation

struct NewConversation: Decodable {
    let id: String

    enum CodingKeys: String, CodingKey {
        case id = "conversationId"
    }
}
