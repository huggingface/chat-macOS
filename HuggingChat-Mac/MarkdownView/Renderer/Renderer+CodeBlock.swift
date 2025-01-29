import Markdown
import SwiftUI

// MARK: - Inline Code Block
extension Renderer {
    mutating func visitInlineCode(_ inlineCode: InlineCode) -> Result {
            let (latexString, isDisplay) = parseLatex(from: inlineCode.code)
            
            if let latexString {
                return Result(
                    Group {
                        if isDisplay {
                            ScrollView(.horizontal, showsIndicators: true) {
                                MathView(equation: latexString,
                                       fontSize: 12,
                                       labelMode: .display)
                                    .fixedSize()
                                    .padding()
                            }
                            .scrollClipDisabled()
//                            .background(.green)
                        } else {
                            MathView(equation: latexString,
                                   fontSize: 14,
                                     labelMode: .display)
//                            .fixedSize()
                            .background(.red)
                        }
                    }
                )
            }
            
            var attributedString = AttributedString(stringLiteral: inlineCode.code)
            attributedString.font = .custom("Menlo Regular", size: 12, relativeTo: .callout)
            return Result(SwiftUI.Text(attributedString))
        }
    
    func visitInlineHTML(_ inlineHTML: InlineHTML) -> Result {
        Result(SwiftUI.Text(inlineHTML.rawHTML))
    }
    
    private func parseLatex(from code: String) -> (latex: String?, isDisplay: Bool) {
            if code.hasPrefix("$$") && code.hasSuffix("$$") {
                return (String(code.dropFirst(2).dropLast(2)), true)
            }
            
            if code.hasPrefix("$") && code.hasSuffix("$") {
                return (String(code.dropFirst().dropLast()), false)
            }
            
            if code.hasPrefix(#"\["#) && code.hasSuffix(#"\]"#) {
                return (String(code.dropFirst(2).dropLast(2)), true)
            }
            
            if code.hasPrefix(#"\("#) && code.hasSuffix(#"\)"#) {
                return (String(code.dropFirst(2).dropLast(2)), false)
            }
            
            return (nil, false)
        }
}

// MARK: - Code Block

extension Renderer {
    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> Result {
        let code = codeBlock.code.trimmingCharacters(in: .newlines)
        
        let latexString: String? = {
            if code.hasPrefix(#"\["#) && code.hasSuffix(#"\]"#) {
                return String(codeBlock.code.dropFirst(2).dropLast(2))
            }
            
            return nil
        }()
        
        if let latexString {
            return Result(
                MathView(equation: latexString,
                       fontSize: 14,
                       labelMode: .text)
                .fixedSize()
                .background(.blue)
            )
        }
        
        return Result {
            #if canImport(Highlightr)
            HighlightedCodeBlock(
                language: codeBlock.language,
                code: codeBlock.code,
                theme: configuration.codeBlockTheme
            )
            #else
            SwiftUI.Text(codeBlock.code)
            #endif
        }
    }
    
    func visitHTMLBlock(_ html: HTMLBlock) -> Result {
        // Forced conversion of text to view
        Result {
            SwiftUI.Text(html.rawHTML)
        }
    }
}

#Preview {
    MarkdownLatexTestView()
        .frame(width: 300, height: 400)
        .textSelection(.enabled)
}
