//
//  ResponseParsingTask.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/29/24.
//

///Credit: Alfian Losari https://github.com/alfianlosari/ChatGPTSwiftUI
import Foundation
import Markdown

class ResponseParsingTask {
    
    private let isDarkMode: Bool
    lazy var markdownParser = MarkdownAttributedStringParser(isDarkMode: isDarkMode)

    func parse(text: String) -> AttributedOutput {
        let document = Document(parsing: text)
        let results = markdownParser.parserResults(from: document)
        return AttributedOutput(string: text, results: results)
    }
    
    init(isDarkMode: Bool) {
        self.isDarkMode = isDarkMode
    }

}
