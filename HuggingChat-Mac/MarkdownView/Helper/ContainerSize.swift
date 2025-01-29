import SwiftUI

struct ContainerSize: EnvironmentKey {
    static let defaultValue: CGSize = .zero
}

extension EnvironmentValues {
    var containerSize: CGSize {
        get { self[ContainerSize.self] }
        set { self[ContainerSize.self] = newValue }
    }
}

extension View {
    func containerSize(_ size: CGSize) -> some View {
        environment(\.containerSize, size)
    }
}
