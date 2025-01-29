import SwiftUI

struct BlockQuoteTint: EnvironmentKey {
    static let defaultValue: Color = Color.accentColor
}

struct InlineCodeBlockTint: EnvironmentKey {
    static let defaultValue = Color.accentColor
}

extension EnvironmentValues {
    var blockQuoteTint: Color {
        get { self[BlockQuoteTint.self] }
        set { self[BlockQuoteTint.self] = newValue }
    }
    var inlineCodeBlockTint: Color {
        get { self[InlineCodeBlockTint.self] }
        set { self[InlineCodeBlockTint.self] = newValue }
    }
}

/// Components that can apply a tint color.
public enum TintableComponent {
    case blockQuote
    case inlineCodeBlock
}

public extension View {
    /// Sets the tint color for specific MarkdownView component.
    ///
    /// - Parameters:
    ///   - tint: The tint color to apply.
    ///   - component: The tintable component to apply the tint color.
    @ViewBuilder func tint(_ tint: Color, for component: TintableComponent) -> some View {
        switch component {
        case .blockQuote:
            environment(\.blockQuoteTint, tint)
        case .inlineCodeBlock:
            environment(\.inlineCodeBlockTint, tint)
        }
    }
}
