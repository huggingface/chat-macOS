//
//  LLMModel.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/23/24.
//

import Foundation

final class LLMModel: Codable, Identifiable, BaseConversation {
    
    let id: String
    let name: String
    let displayName: String
    let websiteUrl: URL
    let modelUrl: URL
    let promptExamples: [PromptExample]
    let multimodal: Bool
    let unlisted: Bool
    let description: String
    var preprompt: String

    init(
        id: String, name: String, displayName: String, websiteUrl: URL, modelUrl: URL,
        promptExamples: [PromptExample], multimodal: Bool, unlisted: Bool, description: String,
        isActive: Bool, preprompt: String
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.websiteUrl = websiteUrl
        self.modelUrl = modelUrl
        self.promptExamples = promptExamples
        self.multimodal = multimodal
        self.unlisted = unlisted
        self.description = description
        self.preprompt = preprompt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.displayName = try container.decode(String.self, forKey: .displayName)

        if let url = try? container.decode(URL.self, forKey: .websiteUrl) {
            self.websiteUrl = url
        } else {
            self.websiteUrl = URL(string: "https://huggingface.co/\(self.name)")!
        }
        
        if let url = try? container.decode(URL.self, forKey: .modelUrl) {
            self.modelUrl = url
        } else {
            self.modelUrl = URL(string: "https://huggingface.co/\(self.name)")!
        }

        self.promptExamples = (try? container.decode([PromptExample].self, forKey: .promptExamples)) ?? []
        
        self.multimodal = try container.decode(Bool.self, forKey: .multimodal)
        self.unlisted = try container.decode(Bool.self, forKey: .unlisted)
        self.description = (try? container.decode(String.self, forKey: .description)) ?? ""

        self.preprompt = try container.decode(String.self, forKey: .preprompt)
    }

}

extension LLMModel {
    static func dumbModel() -> LLMModel {
        let examples = [
            PromptExample(
                title: "Write an email from bullet list", prompt: "Write an email from bullet list"),
            PromptExample(title: "Code a snake game", prompt: "Code a snake game"),
            PromptExample(title: "Assist in a task", prompt: "Assist in a task"),
        ]
        return LLMModel(
            id: "NousResearch/Nous-Hermes-2-Mixtral-8x7B-DPO",
            name: "NousResearch/Nous-Hermes-2-Mixtral-8x7B-DPO",
            displayName: "NousResearch/Nous-Hermes-2-Mixtral-8x7B-DPO",
            websiteUrl: URL(string: "https://google.fr")!,
            modelUrl: URL(string: "https://google.fr")!, promptExamples: examples,
            multimodal: false,
            unlisted: false, description: "", isActive: true, preprompt: "")
    }
    
    func toNewConversation() -> (AnyObject&Codable) {
        return NewConversationFromModelRequestBody(model: id, preprompt: preprompt)
    }
}

struct PromptExample: Codable {
    let title: String
    let prompt: String
}
