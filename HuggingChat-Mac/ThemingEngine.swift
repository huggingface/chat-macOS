//
//  ThemingEngine.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 9/21/24.
//

import SwiftUI
import MarkdownView

struct Theme {
    var name: ThemeNames
    var previewImage: String
    var quickBarIcon: String
    var quickBarFont: Font
    var markdownFont: ThemedFontGroup?
    
    var animatedMeshMainColors: [Color]
    var animatedMeshHighlightColors: [Color]
}

enum ThemeNames: String, CaseIterable {
    case defaultTheme = "Default"
    case appleClassic = "McIntosh Classic"
    case chromeDino = "404"
    case pixelPals = "Pixel Pals"
}

enum FontType {
    case custom(String)
}

struct ThemedFontGroup: MarkdownFontGroup {
    private let fontType: FontType
    private let monospacedFontType: FontType
    private let serifFontType: FontType
    private let fontMultiplier: CGFloat
    
    init(fontType: FontType, monospacedFontType: FontType? = nil, serifFontType: FontType? = nil, fontMultiplier: CGFloat? = nil) {
        self.fontType = fontType
        self.monospacedFontType = monospacedFontType ?? fontType
        self.serifFontType = serifFontType ?? fontType
        self.fontMultiplier = fontMultiplier ?? 1
    }
    
    private func getFont(for fontType: FontType, size: CGFloat) -> Font {
        switch fontType {
        case .custom(let name):
            return .custom(name, size: size)
        }
    }
    
    private func systemFontSize(for textStyle: Font.TextStyle) -> CGFloat {
        switch textStyle {
        case .largeTitle: return NSFont.preferredFont(forTextStyle: .headline).pointSize * fontMultiplier
        case .subheadline: return NSFont.preferredFont(forTextStyle: .subheadline).pointSize * fontMultiplier
        case .title: return NSFont.preferredFont(forTextStyle: .headline).pointSize * fontMultiplier
        case .title2: return NSFont.preferredFont(forTextStyle: .title2).pointSize * fontMultiplier
        case .title3: return NSFont.preferredFont(forTextStyle: .title3).pointSize * fontMultiplier
        case .headline: return NSFont.preferredFont(forTextStyle: .headline).pointSize * fontMultiplier
        case .body: return NSFont.preferredFont(forTextStyle: .body).pointSize * fontMultiplier
        case .callout: return NSFont.preferredFont(forTextStyle: .callout).pointSize * fontMultiplier
        default: return NSFont.preferredFont(forTextStyle: .body).pointSize * fontMultiplier
        }
    }
    
    var h1: Font { getFont(for: fontType, size: systemFontSize(for: .largeTitle)) }
    var h2: Font { getFont(for: fontType, size: systemFontSize(for: .title)) }
    var h3: Font { getFont(for: fontType, size: systemFontSize(for: .title2)) }
    var h4: Font { getFont(for: fontType, size: systemFontSize(for: .title3)) }
    var h5: Font { getFont(for: fontType, size: systemFontSize(for: .headline)) }
    var h6: Font { getFont(for: fontType, size: systemFontSize(for: .headline)) }
    var footnote: Font { getFont(for: fontType, size: systemFontSize(for: .footnote)) }
    
    var body: Font { getFont(for: fontType, size: systemFontSize(for: .body)) }
    
    var codeBlock: Font { getFont(for: monospacedFontType, size: systemFontSize(for: .callout)) }
    var blockQuote: Font { getFont(for: serifFontType, size: systemFontSize(for: .body)) }
    
    var tableHeader: Font { getFont(for: fontType, size: systemFontSize(for: .headline)) }
    var tableBody: Font { getFont(for: fontType, size: systemFontSize(for: .body)) }
}

@Observable class ThemingEngine {
    static let shared: ThemingEngine = ThemingEngine()
    
    private(set) var currentTheme: Theme
    
    init() {
        if let savedThemeName = UserDefaults.standard.string(forKey: "selectedTheme"),
           let savedTheme = ThemeNames(rawValue: savedThemeName) {
            self.currentTheme = Self.theme(for: savedTheme)
        } else {
            self.currentTheme = Self.defaultTheme
        }
    }
    
    static func theme(for name: ThemeNames) -> Theme {
        switch name {
        case .defaultTheme:
            return defaultTheme
        case .appleClassic:
            return appleClassicTheme
        case .chromeDino:
            return chromeDinoTheme
        case .pixelPals:
            return pixelPalsTheme
        }
    }
    
    func setTheme(_ themeName: ThemeNames) {
        switch themeName {
        case .defaultTheme:
            currentTheme = Self.defaultTheme
        case .appleClassic:
            currentTheme = Self.appleClassicTheme
        case .chromeDino:
            currentTheme = Self.chromeDinoTheme
        case .pixelPals:
            currentTheme = Self.pixelPalsTheme
        }
        UserDefaults.standard.set(themeName.rawValue, forKey: "selectedTheme")
    }
    
    static var defaultTheme: Theme {
        Theme(
            name: .defaultTheme,
            previewImage: "huggy.bp",
            quickBarIcon: "plus",
            quickBarFont: Font.system(.title3),
            markdownFont: nil,
            animatedMeshMainColors: [.blue, .purple, .indigo, .pink, .red, .mint, .teal, .cyan],
            animatedMeshHighlightColors: []
        )
    }
    
    static var appleClassicTheme: Theme {
        Theme(
            name: .appleClassic,
            previewImage: "huggy.classic",
            quickBarIcon: "plusApple",
            quickBarFont: Font.custom("ChicagoFLF", size: 15, relativeTo: .title3),
            markdownFont:  ThemedFontGroup(fontType: .custom("ChicagoFLF"), fontMultiplier: 1),
            animatedMeshMainColors: [.green, .yellow, .orange, .red, .purple, .blue],
            animatedMeshHighlightColors: []
        )
    }
    
    static var chromeDinoTheme: Theme {
        Theme(
            name: .chromeDino,
            previewImage: "huggy.404",
            quickBarIcon: "chromeDino",
            quickBarFont: Font.custom("Silom", size: 15, relativeTo: .title3),
            markdownFont:  ThemedFontGroup(fontType: .custom("Silom")),
            animatedMeshMainColors: [.gray, .black, .white],
            animatedMeshHighlightColors: []
        )
    }
    
    static var pixelPalsTheme: Theme {
        Theme(
            name: .pixelPals,
            previewImage: "huggy.pals",
            quickBarIcon: "plusPals",
            quickBarFont: Font.custom("PixeloidSans", size: 15, relativeTo: .title3),
            markdownFont:  ThemedFontGroup(fontType: .custom("PixeloidSans")),
            animatedMeshMainColors: [.green, .yellow, .orange, .red, .purple, .blue],
            animatedMeshHighlightColors: []
        )
    }
}

#Preview {
    let themingEngine = ThemingEngine.shared
    themingEngine.setTheme(.chromeDino)
    
    return ConversationView(columnVisibility: .constant(.automatic))
        .environment(ModelManager())
        .environment(ConversationViewModel())
        .environment(themingEngine)
}
