//
//  Text+Extension.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 11/30/24.
//

import SwiftUI

extension Text {
    func getContrastText(backgroundColor: Color) -> some View {
        let nsColor = NSColor(backgroundColor)
        // Convert to RGB color space first
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else {
            // Fallback to black text if conversion fails
            return self.foregroundColor(.black)
        }
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        rgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return luminance < 0.6 ? self.foregroundColor(.white) : self.foregroundColor(.black)
    }
}
