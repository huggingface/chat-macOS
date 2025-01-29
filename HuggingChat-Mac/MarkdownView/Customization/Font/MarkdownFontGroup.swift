import SwiftUI

/// A type that applies font group to all MarkdownViews within a view hierarchy.
///
/// To configure the current font group for a view hierarchy, use the fontGroup(_:) modifier. Specify a font group that conforms to MarkdownFontGroup when creating a MarkdownVIew.
public protocol MarkdownFontGroup {
    // Headings
    var h1: Font { get }
    var h2: Font { get }
    var h3: Font { get }
    var h4: Font { get }
    var h5: Font { get }
    var h6: Font { get }
    
    // Normal text
    var body: Font { get }
    
    // Blocks
    var codeBlock: Font { get }
    var blockQuote: Font { get }
    
    // Tables
    var tableHeader: Font { get }
    var tableBody: Font { get }
}

extension MarkdownFontGroup {
    public var h1: Font { Font.largeTitle }
    public var h2: Font { Font.title }
    public var h3: Font { Font.title2 }
    public var h4: Font { Font.title3 }
    public var h5: Font { Font.headline }
    public var h6: Font { Font.headline.weight(.regular) }
    
    // Normal text
    public var body: Font { Font.body }
    
    // Blocks
    public  var codeBlock: Font { Font.system(.callout, design: .monospaced) }
    public var blockQuote: Font { Font.system(.body, design: .serif) }
    
    // Tables
    public var tableHeader: Font { Font.headline }
    public var tableBody: Font { Font.body }
}
