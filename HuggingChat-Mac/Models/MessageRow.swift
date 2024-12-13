//
//  MessageRow.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/29/24.
//

import Foundation

struct AttributedOutput {
    let string: String
    let results: [ParserResult]
}

enum MessageRowType {
    case attributed(AttributedOutput)
    case rawText(String)

    var text: String {
        switch self {
        case .attributed(let attributedOutput):
            return attributedOutput.string
        case .rawText(let string):
            return string
        }
    }
}

enum MessageType: CustomStringConvertible {
    var description: String {
        switch self {
        case .user:
            return "user"
        case .assistant:
            return "assistant"
        }
    }
    
    case user
    case assistant
}

final class MessageRow: Identifiable, PromptRequestConvertible {
    

    private(set) var id = UUID().uuidString.lowercased()

    let type: MessageType

    var isInteracting: Bool

    var content: String {
        contentType.text
    }
    var contentType: MessageRowType

    var responseError: String?
    
    var prompt: String {
        return content
    }
    
    var webSearch: WebSearch?
    var fileInfo: FileMessage?
    
    init?(message: Message) {
        self.id = message.id
        switch message.author {
        case .assistant:
            self.type = .assistant
        case .user:
            self.type = .user
        default:
            return nil
        }
        self.isInteracting = false
        self.contentType = .rawText(message.content)
        self.responseError = nil
        self.fileInfo = nil
        
        if let webSearch = message.webSearch {
            self.webSearch = WebSearch(message: "Completed", sources: webSearch.contextSources)
        }
    }
    
    init(id: String = UUID().uuidString.lowercased(), type: MessageType, isInteracting: Bool, contentType: MessageRowType, responseError: String? = nil, fileInfo: FileMessage? = nil) {
        self.id = id
        self.type = type
        self.isInteracting = isInteracting
        self.contentType = contentType
        self.responseError = responseError
        self.fileInfo = fileInfo
    }
    
    func updateID(message: Message) {
        self.id = message.id
    }
}


protocol PromptRequestConvertible {
    var id: String { get }
    var prompt: String { get }
}
