import SwiftUI

/// The font group that describes a set of platform’s dynamic types for each component.
///
/// Use ``MarkdownView/MarkdownFontGroup/automatic`` to construct this type.
public struct DefaultFontGroup: MarkdownFontGroup, Sendable { }

extension MarkdownFontGroup where Self == DefaultFontGroup {
    /// The font group that describes a set of platform’s dynamic types for each component.
    static public var automatic: DefaultFontGroup { .init() }
}
