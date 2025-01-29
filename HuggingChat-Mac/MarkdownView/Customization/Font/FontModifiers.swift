import SwiftUI

// MARK: - View Extensions

public extension View {
    /// Apply a font group to MarkdownView.
    ///
    /// Customize fonts for multiple types of text.
    ///
    /// - Parameter fontGroup: A font set to apply to the MarkdownView.
    func fontGroup(_ fontGroup: some MarkdownFontGroup) -> some View {
        environment(\.fontGroup, .init(fontGroup))
    }
    
    /// Sets the font for the specific component in MarkdownView.
    /// - Parameters:
    ///   - font: The font to apply to these components.
    ///   - type: The type of components to apply the font.
    func font(_ font: Font, for type: MarkdownTextType) -> some View {
        transformEnvironment(\.fontGroup) { group in
            switch type {
            case .h1: group._h1 = font
            case .h2: group._h2 = font
            case .h3: group._h3 = font
            case .h4: group._h4 = font
            case .h5: group._h5 = font
            case .h6: group._h6 = font
            case .body: group._body = font
            case .blockQuote: group._blockQuote = font
            case .codeBlock: group._codeBlock = font
            case .tableBody: group._tableBody = font
            case .tableHeader: group._tableHeader = font
            }
        }
    }
    
    /// Apply a font set to MarkdownView.
    ///
    /// This is useful when you want to completely customize fonts.
    ///
    /// - Parameter fontProvider: A font set to apply to the MarkdownView.
    @available(*, deprecated, renamed: "fontGroup", message: "Use MarkdownFontGroup and fontGroup instead.")
    func markdownFont(_ fontProvider: MarkdownFontProvider) -> some View {
        environment(\.fontGroup, .init(MarkdownFontProviderWrapper(fontProvider)))
    }
}

// MARK: - Environment Values

struct MarkdownFontGroupKey: EnvironmentKey {
    static let defaultValue = AnyMarkdownFontGroup(.automatic)
}

extension EnvironmentValues {
    var fontGroup: AnyMarkdownFontGroup {
        get { self[MarkdownFontGroupKey.self] }
        set { self[MarkdownFontGroupKey.self] = newValue }
    }
}


