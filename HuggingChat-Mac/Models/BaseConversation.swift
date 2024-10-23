//
//  BaseConversation.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/23/24.
//

import Foundation

protocol BaseConversation {
    var id: String { get }
    func toNewConversation() -> (AnyObject&Codable)
}
