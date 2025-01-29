import SwiftUI

@available(*, deprecated, message: "Use MarkdownFontGroup protocol to create your font group.")
/// A font provider that defines fonts for each type of components.
public struct MarkdownFontProvider {
    // Headings
    var h1 = Font.largeTitle
    var h2 = Font.title
    var h3 = Font.title2
    var h4 = Font.title3
    var h5 = Font.headline
    var h6 = Font.headline.weight(.regular)
    
    // Normal text
    var body = Font.body
    
    // Blocks
    var codeBlock = Font.system(.callout, design: .monospaced)
    var blockQuote = Font.system(.body, design: .serif)
    
    // Tables
    var tableHeader = Font.headline
    var tableBody = Font.body
    
    /// Create a font set for MarkdownView to apply to components.
    /// - Parameters:
    ///   - h1: The font for H1.
    ///   - h2: The font for H2.
    ///   - h3: The font for H3.
    ///   - h4: The font for H4.
    ///   - h5: The font for H5.
    ///   - h6: The font for H6.
    ///   - body: The font for body. (normal text)
    ///   - codeBlock: The font for code blocks.
    ///   - blockQuote: The font for block quotes.
    ///   - tableHeader: The font for headers of tables.
    ///   - tableBody: The font for bodies of tables.
    public init(h1: Font = Font.largeTitle, h2: Font = Font.title, h3: Font = Font.title2, h4: Font = Font.title3, h5: Font = Font.headline, h6: Font = Font.headline.weight(.regular), body: Font = Font.body, codeBlock: Font = Font.system(.callout, design: .monospaced), blockQuote: Font = Font.system(.body, design: .serif), tableHeader: Font = Font.headline, tableBody: Font = Font.body) {
        self.h1 = h1
        self.h2 = h2
        self.h3 = h3
        self.h4 = h4
        self.h5 = h5
        self.h6 = h6
        self.body = body
        self.codeBlock = codeBlock
        self.blockQuote = blockQuote
        self.tableHeader = tableHeader
        self.tableBody = tableBody
    }
}

@available(*, deprecated)
extension MarkdownFontProvider {
    mutating func modify(_ type: TextType, font: Font) {
        switch type {
        case .h1: h1 = font
        case .h2: h2 = font
        case .h3: h3 = font
        case .h4: h4 = font
        case .h5: h5 = font
        case .h6: h6 = font
        case .body: body = font
        case .blockQuote: blockQuote = font
        case .codeBlock: codeBlock = font
        case .tableBody: tableBody = font
        case .tableHeader: tableHeader = font
        }
    }
    
    /// The component type of text.
    public enum TextType: Equatable {
        case h1,h2,h3,h4,h5,h6
        case body
        case codeBlock,blockQuote
        case tableHeader,tableBody
    }
}

@available(*, deprecated)
extension MarkdownFontProvider: Equatable {}

@available(*, deprecated, message: "This is a bridge for deprecated MarkdownFontProvider. These APIs will be removed from MarkdownView in the future.")
struct MarkdownFontProviderWrapper: MarkdownFontGroup {
    var h1 = Font.largeTitle
    var h2 = Font.title
    var h3 = Font.title2
    var h4 = Font.title3
    var h5 = Font.headline
    var h6 = Font.headline.weight(.regular)
    var body = Font.body
    var codeBlock = Font.system(.callout, design: .monospaced)
    var blockQuote = Font.system(.body, design: .serif)
    var tableHeader = Font.headline
    var tableBody = Font.body
    
    init(_ provider: MarkdownFontProvider) {
        self.h1 = provider.h1
        self.h2 = provider.h2
        self.h3 = provider.h3
        self.h4 = provider.h4
        self.h5 = provider.h5
        self.h6 = provider.h6
        self.body = provider.body
        self.codeBlock = provider.codeBlock
        self.blockQuote = provider.blockQuote
        self.tableHeader = provider.tableHeader
        self.tableBody = provider.tableBody
    }
}
