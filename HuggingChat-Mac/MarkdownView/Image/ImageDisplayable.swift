import SwiftUI

public protocol ImageDisplayable {
    associatedtype ImageView: View
    
    /// Make the Image View.
    @ViewBuilder func makeImage(url: URL, alt: String?) -> ImageView
}

// MARK: - Built-in providers

/// Load Network Images.
struct NetworkImageDisplayable: ImageDisplayable {
    func makeImage(url: URL, alt: String?) -> some View {
        NetworkImage(url: url, alt: alt)
    }
}

/// Load Images from relative path urls.
struct RelativePathImageDisplayable: ImageDisplayable {
    var baseURL: URL
    
    func makeImage(url: URL, alt: String?) -> some View {
        let completeURL = baseURL.appendingPathComponent(url.absoluteString)
        NetworkImage(url: completeURL, alt: alt)
    }
}

extension ImageDisplayable where Self == RelativePathImageDisplayable {
    static func relativePathImage(baseURL: URL) -> RelativePathImageDisplayable {
        RelativePathImageDisplayable(baseURL: baseURL)
    }
}

/// Load images from your Assets Catalog.
struct AssetImageDisplayable: ImageDisplayable {
    var name: (URL) -> String
    var bundle: Bundle?
    
    func makeImage(url: URL, alt: String?) -> some View {
        #if os(macOS)
        let nsImage: NSImage?
        if let bundle = bundle, bundle != .main {
            nsImage = bundle.image(forResource: name(url))
        } else {
            nsImage = NSImage(named: name(url))
        }
        if let nsImage {
            return MainActor.assumeIsolated {
                AssetImage(image: nsImage, alt: alt)
            }
        }
        #elseif os(iOS) || os(tvOS)
        if let uiImage = UIImage(named: name(url), in: bundle, compatibleWith: nil) {
            return MainActor.assumeIsolated {
                AssetImage(image: uiImage, alt: alt)
            }
        }
        #elseif os(watchOS)
        if let uiImage = UIImage(named: name(url), in: bundle, with: nil) {
            return MainActor.assumeIsolated {
                AssetImage(image: uiImage, alt: alt)
            }
        }
        #endif
        return MainActor.assumeIsolated {
            AssetImage(image: nil, alt: nil)
        }
    }
}

extension ImageDisplayable where Self == AssetImageDisplayable {
    static func assetImage(name: @escaping (URL) -> String = \.lastPathComponent, bundle: Bundle? = nil) -> AssetImageDisplayable {
        AssetImageDisplayable(name: name, bundle: bundle)
    }
}
