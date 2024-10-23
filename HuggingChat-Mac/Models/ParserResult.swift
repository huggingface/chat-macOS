///Credit: Alfian Losari https://github.com/alfianlosari/ChatGPTSwiftUI

import Foundation

enum ParserResultType {
    case codeBlock(String?)
    case text
    case image(String)
}

struct ParserResult: Identifiable {

    let id = UUID()
    let attributedString: NSMutableAttributedString
    let resultType: ParserResultType
}
