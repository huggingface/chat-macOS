import SwiftUI

class ImageRenderer: @unchecked Sendable {
    /// The base URL for local images or network images.
    private(set) var baseURL: URL
    
    /// Create a Configuration for image handling.
    init(baseURL: URL? = nil) {
        guard baseURL == nil else {
            self.baseURL = baseURL!
            return
        }
        
        let baseURL: URL
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            baseURL = .documentsDirectory
        } else {
            baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        }
        self.baseURL = baseURL
    }
    
    /// All the providers that have been added.
    private(set) var imageProviders: [String: any ImageDisplayable] = [
        "http": NetworkImageDisplayable(),
        "https": NetworkImageDisplayable(),
    ]
    
    /// Add custom provider for images rendering.
    /// - Parameters:
    ///   - provider: An image provider to make image using a url and an alternative text.
    ///   - urlScheme: The url scheme to use the provider.
    func addProvider(
        _ provider: some ImageDisplayable, forURLScheme urlScheme: String
    ) {
        self.imageProviders[urlScheme] = provider
    }
    
    func loadImage(
        _ provider: (any ImageDisplayable)?, url: URL, alt: String?
    ) -> AnyView {
        if let provider {
            // Found a specific provider.
            provider.makeImage(url: url, alt: alt)
                .eraseToAnyView()
        } else {
            // No specific provider.
            // Try to load the image from the Base URL.
            RelativePathImageDisplayable(baseURL: baseURL)
                .makeImage(url: url, alt: alt)
                .eraseToAnyView()
        }
    }
    
    func updateBaseURL(_ baseURL: URL?) {
        guard let baseURL else { return }
        self.baseURL = baseURL
    }
}
