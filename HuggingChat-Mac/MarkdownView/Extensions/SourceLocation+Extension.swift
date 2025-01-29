import Markdown
import SwiftUI

extension SourceLocation {
    func offset(in text: String) -> Int {
        let colIndex = column - 1
        let previousLinesTotalChar = text
            .split(separator: "\n", maxSplits: line - 1, omittingEmptySubsequences: false)
            .dropLast()
            .map { String($0) }
            .joined(separator: "\n")
            .count
        return previousLinesTotalChar + colIndex + 1
    }
}

#Preview {
    MarkdownLatexTestView()
        .frame(width: 400, height: 400)
        .textSelection(.enabled)
}
