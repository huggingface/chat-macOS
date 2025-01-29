import SwiftUI

// MARK: - View Extensions

extension View {
    /// Add your own providers to render images.
    ///
    /// - parameters
    ///     - provider: The provider you created to handle image loading and displaying.
    ///     - urlScheme: A scheme for the renderer to determine when to use the provider.
    /// - Returns: View that able to render images with specific schemes.
    ///
    /// You can set the provider multiple times if you want to add multiple schemes.
    public func imageProvider(
        _ provider: some ImageDisplayable, forURLScheme urlScheme: String
    ) -> some View {
        transformEnvironment(\.imageRenderer) { renderer in
            renderer.addProvider(provider, forURLScheme: urlScheme)
        }
    }
}


// MARK: - Environment Values
@MainActor
struct MarkdownImageRendererKey: @preconcurrency EnvironmentKey {
    static var defaultValue = ImageRenderer()
}

extension EnvironmentValues {
    var imageRenderer: ImageRenderer {
        get { self[MarkdownImageRendererKey.self] }
        set { self[MarkdownImageRendererKey.self] = newValue }
    }
}
