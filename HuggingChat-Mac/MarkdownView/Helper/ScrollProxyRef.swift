import SwiftUI

@MainActor
class ScrollProxyRef {
    static var shared = ScrollProxyRef()
    private(set) var proxy: ScrollViewProxy?
    
    func setProxy(_ proxy: ScrollViewProxy) {
        self.proxy = proxy
    }
}
