import SwiftUI

struct AssetImage: View {
    var image: PlatformImage?
    var alt: String?
    
    var body: some View {
        if let image {
            #if os(macOS)
            Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
            #else
            Image(uiImage: image).resizable().aspectRatio(contentMode: .fit)
            #endif
            
            if let alt {
                Text(alt).foregroundStyle(.secondary).font(.callout)
            }
        } else {
            ImagePlaceholder()
        }
    }
}
