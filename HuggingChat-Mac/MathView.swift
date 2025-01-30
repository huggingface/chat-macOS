//
//  MathView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/28/25.
//

import SwiftUI
import SwiftMath

struct MathView: NSViewRepresentable {
    var equation: String
    var font: MathFont = .latinModernFont
    var textAlignment: MTTextAlignment = .left
    var fontSize: CGFloat = 12
    var labelMode: MTMathUILabelMode = .text
    var insets: MTEdgeInsets = MTEdgeInsets()
    var convertToImage: Bool = false
    
    func makeNSView(context: Context) -> MTMathUILabel {
        let view = MTMathUILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    func updateNSView(_ view: MTMathUILabel, context: Context) {
        view.latex = equation
        view.font = MTFontManager().font(withName: font.rawValue, size: fontSize)
        view.textAlignment = textAlignment
        view.labelMode = labelMode
        view.textColor = MTColor(Color.primary)
        view.contentInsets = MTEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }
}


#Preview {
    MarkdownLatexTestView()
        .frame(width: 300, height: 400)
        .textSelection(.enabled)
}

//#Preview {
//    ScrollView(.horizontal) {
//        MathImageView(equation: "x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}",
//                            fontSize: 20)
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        
//    }
//}
