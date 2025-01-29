import SwiftUI

// MARK: - View Extensions

extension View {
    /// Adds your custom block directive provider.
    ///
    /// - parameters:
    ///     - provider: The provider you have created to handle block displaying.
    ///     - name: The name of the  block directive.
    /// - Returns: `MarkdownView` with custom directive block loading behavior.
    ///
    /// You can set this provider multiple times if you have multiple providers.
    public func blockDirectiveProvider(
        _ provider: some BlockDirectiveDisplayable, for name: String
    ) -> some View {
        transformEnvironment(\.blockDirectiveRenderer) { p in
            p.addProvider(provider, for: name)
        }
    }
}

// MARK: - Environment Values
@MainActor
struct MarkdownBlockDirectiveKey: @preconcurrency EnvironmentKey {
    static let defaultValue = BlockDirectiveRenderer()
}

extension EnvironmentValues {
    var blockDirectiveRenderer: BlockDirectiveRenderer {
        get { self[MarkdownBlockDirectiveKey.self] }
        set { self[MarkdownBlockDirectiveKey.self] = newValue }
    }
}
