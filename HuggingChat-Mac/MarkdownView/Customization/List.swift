import SwiftUI

struct ListIndentEnvironmentKey: EnvironmentKey {
    static let defaultValue: CGFloat = 12
}

extension EnvironmentValues {
    var listIndent: CGFloat {
        get { self[ListIndentEnvironmentKey.self] }
        set { self[ListIndentEnvironmentKey.self] = newValue }
    }
}

public extension View {
    func markdownListIndent(_ indent: CGFloat) -> some View {
        self.environment(\.listIndent, indent)
    }
}


struct UnorderedListBulletEnvironmentKey: EnvironmentKey {
    static let defaultValue: String = "•"
}

extension EnvironmentValues {
    var unorderedListBullet: String {
        get { self[UnorderedListBulletEnvironmentKey.self] }
        set { self[UnorderedListBulletEnvironmentKey.self] = newValue }
    }
}

public extension View {
    func markdownUnorderedListBullet(_ bullet: String) -> some View {
        self.environment(\.unorderedListBullet, bullet)
    }
}


struct UnorderedListBulletFontEnvironmentKey: EnvironmentKey {
    static let defaultValue: Font = .title2.weight(.black)
}

extension EnvironmentValues {
    var unorderedListBulletFont: Font {
        get { self[UnorderedListBulletFontEnvironmentKey.self] }
        set { self[UnorderedListBulletFontEnvironmentKey.self] = newValue }
    }
}

public extension View {
    func unorderedListBullet(_ font: Font) -> some View {
        self.environment(\.unorderedListBulletFont, font)
    }
}
