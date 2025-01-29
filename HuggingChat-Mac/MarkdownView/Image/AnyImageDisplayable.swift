import SwiftUI

struct AnyImageDisplayable: ImageDisplayable {
    typealias ImageView = AnyView

    @ViewBuilder private let displayableClosure: (URL, String?) -> AnyView
    
    init<D: ImageDisplayable>(erasing imageDisplayable: D) {
        displayableClosure = { url, alt in
            AnyView(imageDisplayable.makeImage(url: url, alt: alt))
        }
    }

    func makeImage(url: URL, alt: String?) -> AnyView {
        displayableClosure(url, alt)
    }
}
