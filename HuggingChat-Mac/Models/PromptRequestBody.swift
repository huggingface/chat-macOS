//
//  PromptRequestBody.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/23/24.
//

import Foundation

struct PromptRequestBody: Encodable {
    let id: String?
    var files: [String]? = nil
    let inputs: String?
    let isRetry: Bool?
    let isContinue: Bool?
    let webSearch: Bool?
    
    init(id: String? = nil, inputs: String? = nil, isRetry: Bool = false, isContinue: Bool = false, webSearch: Bool = false, files: [String]? = nil) {
        self.id = id
        self.inputs = inputs
        self.isRetry = isRetry
        self.isContinue = isContinue
        self.webSearch = webSearch
        self.files = files
    }
}
