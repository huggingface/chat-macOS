import SwiftUI
import Markdown

/// A type for rendering directive blocks.
public protocol BlockDirectiveDisplayable {
    associatedtype BlockDirectiveView: View
    
    /// Create your own custom view with the directive argument.
    /// - Parameters:
    ///   - arguments: A directive argument, parsed from the form name: value or name: "value".
    ///   - text: Text inside the block.
    /// - Returns: A custom block view within MarkdownView.
    @ViewBuilder func makeView(
        arguments: [BlockDirectiveArgument],
        text: String
    ) -> BlockDirectiveView
}

/// Directive Block arguments represented from `swift-markdown/DirectiveArgument`.
public struct BlockDirectiveArgument {
    /// The name of the argument.
    public var name: String
    
    /// The value of that argument.
    public var value: String
    
    /// An argument that represented from ``Markdown/DirectiveArgument``.
    /// - Parameter directiveArgument: The `DirectiveArgument` of the directive block.
    init(_ directiveArgument: DirectiveArgument) {
        name = directiveArgument.name
        value = directiveArgument.value
    }
}


