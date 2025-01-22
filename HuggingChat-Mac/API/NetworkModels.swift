//
//  NetworkModels.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/22/25.
//

import Foundation

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

