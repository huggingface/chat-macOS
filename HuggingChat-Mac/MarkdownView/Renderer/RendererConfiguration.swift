import SwiftUI



struct RendererConfiguration: Equatable {
    var role: MarkdownViewRole
    
    /// Sets the amount of space between lines in a paragraph in this view.
    ///
    /// Use SwiftUI's built-in `lineSpacing(_:)` to set the amount of spacing
    /// from the bottom of one line to the top of the next for text elements in the view.
    ///
    ///     MarkdownView(...)
    ///         .lineSpacing(10)
    var lineSpacing: CGFloat
    var componentSpacing: CGFloat
    var inlineCodeTintColor: Color
    var blockQuoteTintColor: Color
    
    var fontGroup: AnyMarkdownFontGroup
    var foregroundStyleGroup: AnyMarkdownForegroundStyleGroup
    
    /// Sets the theme of the code block.
    /// For more information, please check out [raspu/Highlightr](https://github.com/raspu/Highlightr) .
    var codeBlockTheme: CodeHighlighterTheme

    var listIndent: CGFloat
    var unorderedListBullet: String
}
