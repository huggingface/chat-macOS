import SwiftUI

#if canImport(Highlightr)
@preconcurrency import Highlightr
#endif

#if canImport(Highlightr)
struct HighlightedCodeBlock: View {
    var language: String?
    var code: String
    var theme: CodeHighlighterTheme
    
    @Environment(\.fontGroup) private var font
    @Environment(\.colorScheme) private var colorScheme
    @State private var attributedCode: AttributedString?
    @State private var showCopyButton = false
    
    private var id: String {
        "\(colorScheme) mode" + (language ?? "Plain Text") + code
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                codeLanguage
                    .foregroundStyle(.primary)
                Spacer()
                CopyButton(content: code)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .background(.ultraThickMaterial)
            
            Divider().foregroundStyle(.gray)
            Group {
                if let attributedCode {
                    ScrollView(.horizontal) {
                        SwiftUI.Text(attributedCode)
                    }
                    .contentMargins(.horizontal, 20, for: .scrollContent)
                    .scrollIndicators(.hidden)
                    .contentMargins(.top, 20, for: .scrollContent)
                } else {
                    ScrollView(.horizontal) {
                        SwiftUI.Text(code)
                    }
                    .contentMargins(.horizontal, 20, for: .scrollContent)
                    .scrollIndicators(.hidden)
                    .contentMargins(.top, 20, for: .scrollContent)
                }
            }
            
        }
        .task(id: id, highlight)
        .lineSpacing(5)
        .font(font.codeBlock)
        
        .frame(maxWidth: .infinity, alignment: .leading)
        .mask(RoundedRectangle(cornerRadius: 8))
        .background {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.gray.opacity(0.5))
                .fill( colorScheme == .dark ? Color(red: 32/255, green: 32/255, blue: 32/255): .white)
        }
        .gesture(
            TapGesture()
                .onEnded { _ in showCopyButton.toggle() }
        )
//        .overlay(alignment: .topTrailing) {
//            if showCopyButton {
//                CopyButton(content: code)
//                    .padding(8)
//                    .transition(.opacity.animation(.easeInOut))
//            }
//        }
//        .overlay(alignment: .bottomTrailing) {
//            codeLanguage
//        }
//        .onHover { showCopyButton = $0 }
    }
    
    @ViewBuilder
    private var codeLanguage: some View {
        if let language {
            SwiftUI.Text(language.lowercased())
                .font(.callout)
                .padding(8)
                
        }
    }
    
    private func highlight() async {
        guard let highlighter = await Highlightr.shared.value else { return }
        highlighter.setTheme(to: colorScheme == .dark ? theme.darkModeThemeName:theme.lightModeThemeName)
        let specifiedLanguage = self.language?.lowercased() ?? ""
        
        let language = highlighter.supportedLanguages()
            .first(where: { $0.localizedCaseInsensitiveCompare(specifiedLanguage) == .orderedSame })
        if let highlightedCode = highlighter.highlight(code, as: language) {
            let code = NSMutableAttributedString(attributedString: highlightedCode)
            code.removeAttribute(.font, range: NSMakeRange(0, code.length))
            attributedCode = AttributedString(code)
        }
    }
}
#endif

#Preview {
    MarkdownLatexTestView()
        .frame(width: 300, height: 400)
        .textSelection(.enabled)
}
