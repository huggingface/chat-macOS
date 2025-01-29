import SwiftUI
import Markdown

extension Renderer {
    func visitSoftBreak(_ softBreak: SoftBreak) -> Result {
        Result(SwiftUI.Text(" "))
    }
    
    func visitThematicBreak(_ thematicBreak: ThematicBreak) -> Result {
        Result(Divider())
    }

    func visitLineBreak(_ lineBreak: LineBreak) -> Result {     
        Result(SwiftUI.Text("\n"))
    }
}

#Preview {
    MarkdownLatexTestView()
        .frame(width: 400, height: 400)
        .textSelection(.enabled)
}
