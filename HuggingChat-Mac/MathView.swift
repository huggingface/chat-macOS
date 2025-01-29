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
    var textAlignment: MTTextAlignment = .center
    var fontSize: CGFloat = 12
    var labelMode: MTMathUILabelMode = .display
    var insets: MTEdgeInsets = MTEdgeInsets()
    
    func makeNSView(context: Context) -> MTMathUILabel {
        let view = MTMathUILabel()
        return view
    }
    
    func updateNSView(_ view: MTMathUILabel, context: Context) {
        view.latex = equation
        view.font = MTFontManager().font(withName: font.rawValue, size: fontSize)
        view.textAlignment = textAlignment
        view.labelMode = labelMode
        view.textColor = MTColor(Color.primary)
        view.contentInsets = insets
    }
}

#Preview {
    ScrollView(.horizontal) {
        MathView(equation: "L^{PPO}(\\theta) = \\mathbb{E}_{s,a \\sim \\pi_\\theta} \\left[ \\min \\left( r(\\theta) \\cdot A(s,a), \\text{clip}(r(\\theta), 1 - \\epsilon, 1 + \\epsilon) \\cdot A(s,a) \\right) \\right]", fontSize: 16,
                 labelMode: .text)
        .textSelection(.enabled)
            .padding()
    }
}
