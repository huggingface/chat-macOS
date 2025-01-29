import Markdown
import SwiftUI
import Foundation

struct LinkAttributer: MarkupVisitor {
    var tint: Color
    var font: Font
    typealias Result = AttributedString
    
    mutating func defaultVisit(_ markup: Markup) -> Result {
        var attributedString = AttributedString()
        for child in markup.children {
            attributedString += visit(child)
        }
        return attributedString
    }
    
    func visitText(_ text: Markdown.Text) -> Result {
        var attributedString = Result(stringLiteral: text.plainText)
        attributedString.font = font
        return attributedString
    }
    
    mutating func visitLink(_ link: Markdown.Link) -> Result {
        var attributedString = attributedString(from: link)
        if let destination = link.destination {
            attributedString.link = URL(string: destination)
        } else {
            #if os(macOS)
            attributedString.foregroundColor = .linkColor
            #elseif os(iOS)
            attributedString.foregroundColor = .link
            #elseif os(watchOS)
            attributedString.foregroundColor = .blue
            #endif
        }
        return attributedString
    }
    
    mutating func visitStrong(_ strong: Strong) -> Result {
        var attributedString = attributedString(from: strong)
        attributedString.font = font.bold()
        return attributedString
    }
    
    mutating func visitEmphasis(_ emphasis: Emphasis) -> Result {
        var attributedString = attributedString(from: emphasis)
        attributedString.font = font.italic()
        return attributedString
    }
    
    mutating func visitInlineCode(_ inlineCode: InlineCode) -> Result {
        var attributedString = attributedString(inlineCode.code, from: inlineCode)
        attributedString.foregroundColor = tint
        attributedString.backgroundColor = tint.opacity(0.1)
        return attributedString
    }
    
    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) -> Result {
        var attributedString = attributedString(inlineHTML.rawHTML, from: inlineHTML)
        attributedString.font = font
        return attributedString
    }
}

extension LinkAttributer {
    mutating internal func attributedString(
        _ text: String = "",
        from markup: some Markup
    ) -> Result {
        var attributedString = AttributedString(stringLiteral: text)
        for child in markup.children {
            attributedString += visit(child)
        }
        return attributedString
    }
}
