import SwiftUI

/// The role of MarkdownView, which affects how MarkdownView is rendered.
public enum MarkdownViewRole: Sendable {
    /// The normal role.
    ///
    /// A role that makes the view take the space it needs and center contents, like a normal SwiftUI View.
    case normal
    /// The editor role.
    ///
    /// A role that makes the view take the maximum space
    /// and align its content in the top-leading, just like an editor.
    ///
    /// A Markdown Editor typically use this mode to provide a Live Preview.
    ///
    /// - note: Editor mode is unsupported on watchOS.
    case editor
}

struct MarkdownViewRoleKey: EnvironmentKey {
    static let defaultValue = MarkdownViewRole.normal
}

extension EnvironmentValues {
    var markdownViewRole: MarkdownViewRole {
        get { self[MarkdownViewRoleKey.self] }
        set { self[MarkdownViewRoleKey.self] = newValue }
    }
}

// MARK: - MarkdownView Role

extension View {
    ///  Configures the role of the markdown view.
    /// - Parameter role: A role to tell MarkdownView how to render its content.
    public func markdownViewRole(_ role: MarkdownViewRole) -> some View {
        #if os(watchOS)
        environment(\.markdownViewRole, .normal)
        #else
        environment(\.markdownViewRole, role)
        #endif
    }
}
