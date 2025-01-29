import SwiftUI

// MARK: - View Extensions

public extension View {
    /// Apply a foreground style group to MarkdownView.
    ///
    /// This is useful when you want to completely customize foreground styles.
    ///
    /// - Parameter foregroundStyleGroup: A style set to apply to the MarkdownView.
    @ViewBuilder
    func foregroundStyleGroup(_ foregroundStyleGroup: some MarkdownForegroundStyleGroup) -> some View {
        environment(\.foregroundStyleGroup, .init(foregroundStyleGroup))
    }
    
    /// Sets foreground style for the specific component in MarkdownView.
    ///
    /// - Parameters:
    ///   - style: The style to apply to this type of components.
    ///   - component: The type of components to apply the foreground style.
    @ViewBuilder
    func foregroundStyle(_ style: some ShapeStyle, for component: ColorableComponent) -> some View {
        transformEnvironment(\.foregroundStyleGroup) { group in
            let erasedShapeStyle = AnyShapeStyle(style)
            switch component {
            case .h1: group._h1 = erasedShapeStyle
            case .h2: group._h2 = erasedShapeStyle
            case .h3: group._h3 = erasedShapeStyle
            case .h4: group._h4 = erasedShapeStyle
            case .h5: group._h5 = erasedShapeStyle
            case .h6: group._h6 = erasedShapeStyle
            case .blockQuote: group._blockQuote = erasedShapeStyle
            case .codeBlock: group._codeBlock = erasedShapeStyle
            case .tableBody: group._tableBody = erasedShapeStyle
            case .tableHeader: group._tableHeader = erasedShapeStyle
            }
        }
    }
}


// MARK: - Environment Values

struct MarkdownForegroundStyleGroupKey: EnvironmentKey {
    static let defaultValue = AnyMarkdownForegroundStyleGroup(.automatic)
}

extension EnvironmentValues {
    var foregroundStyleGroup: AnyMarkdownForegroundStyleGroup {
        get { self[MarkdownForegroundStyleGroupKey.self] }
        set { self[MarkdownForegroundStyleGroupKey.self] = newValue }
    }
}
