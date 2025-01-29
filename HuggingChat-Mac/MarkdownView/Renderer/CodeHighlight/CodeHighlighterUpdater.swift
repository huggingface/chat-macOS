#if canImport(Highlightr)
@preconcurrency import Highlightr
#endif
import SwiftUI

/// A responder that update the theme of highlightr when environment value changes.
struct CodeHighlighterUpdater: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.codeHighlighterTheme) private var theme: CodeHighlighterTheme
    
    @State private var highlightrUpdateTaskCache: Task<Void, Error>?
    
    func body(content: Content) -> some View {
        content
            #if canImport(Highlightr)
            .onChange(of: colorScheme) { colorScheme in
                highlightrUpdateTaskCache?.cancel()
                highlightrUpdateTaskCache = Task {
                    let theme = colorScheme == .dark ? theme.darkModeThemeName : theme.lightModeThemeName
                    let highlighr = await Highlightr.shared.value
                    try Task.checkCancellation()
                    highlighr?.setTheme(to: theme)
                }
            }
            .onChange(of: theme) { newTheme in
                highlightrUpdateTaskCache?.cancel()
                highlightrUpdateTaskCache = Task {
                    let theme = colorScheme == .dark ? newTheme.darkModeThemeName : newTheme.lightModeThemeName
                    let highlighr = await Highlightr.shared.value
                    try Task.checkCancellation()
                    highlighr?.setTheme(to: theme)
                }
            }
            #endif
    }
}
