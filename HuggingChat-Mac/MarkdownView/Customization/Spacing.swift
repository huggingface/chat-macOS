import SwiftUI

struct ComponentSpacingEnvironmentKey: EnvironmentKey {
    static let defaultValue: CGFloat = 8
}

extension EnvironmentValues {
    var componentSpacing: CGFloat {
        get { self[ComponentSpacingEnvironmentKey.self] }
        set { self[ComponentSpacingEnvironmentKey.self] = newValue }
    }
}

public extension View {
    func markdownComponentSpacing(_ spacing: CGFloat) -> some View {
        self.environment(\.componentSpacing, spacing)
    }
}
