import Foundation

public enum MarkdownTextType: Equatable, CaseIterable {
    case h1,h2,h3,h4,h5,h6
    case body
    case codeBlock,blockQuote
    case tableHeader,tableBody
}
