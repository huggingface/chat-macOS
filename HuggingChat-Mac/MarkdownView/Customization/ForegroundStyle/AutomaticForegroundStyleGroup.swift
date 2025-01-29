import SwiftUI

/// A foreground style group that resolves its content appearance automatically based on the current context.
///
/// Use ``MarkdownView/MarkdownForegroundStyleGroup/automatic`` to construct this type.
public struct AutomaticForegroundStyleGroup: MarkdownForegroundStyleGroup { }

extension MarkdownForegroundStyleGroup where Self == AutomaticForegroundStyleGroup {
    /// A foreground style group that resolves its content appearance automatically based on the current context.
    static public var automatic: AutomaticForegroundStyleGroup { .init() }
}

