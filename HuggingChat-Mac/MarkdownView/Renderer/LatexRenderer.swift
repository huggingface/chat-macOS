//
//  LatexRenderer.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/29/25.
//

import MathJaxSwift
import SwiftUI

public enum LaTeXRenderer {
    public enum LaTeXRendererError: Error {
        case mathJaxUninitialized
        case svgNoData
        case couldNotCreateSVG
    }
    
    public struct CachedImage {
        var svgImageScale: CGFloat
        var image: Image
    }
    
    // key: latexString, value: image
    public static var cache = [String: CachedImage]()
    
    public static func flushCache() {
        cache = [:]
    }
    
    public static var mathJax: MathJax? = {
        do {
            let mathJax = try MathJax()
            return mathJax
        } catch {
            print("LatexRenderer: Couldn't initialize MathJax. \(error)")
        }
        
        return nil
    }()
    
    public static var texOptions = TeXInputProcessorOptions(loadPackages: [TeXInputProcessorOptions.Packages.ams, TeXInputProcessorOptions.Packages.amscd])
    
    public static func renderImage(latexString: String, svgImageScale: CGFloat = 0.1) throws -> Image {
        if let cachedImage = cache[latexString] {
            if cachedImage.svgImageScale == svgImageScale {
                return cachedImage.image
            } else {
                // remove the cached image, because the scale is wrong
                cache[latexString] = nil
            }
        }
        
        let svgString = try renderSVG(latexString: latexString)
        let image = try svgToImage(svgString: svgString, svgImageScale: svgImageScale)
        cache[latexString] = CachedImage(svgImageScale: svgImageScale, image: image)
        return image
    }
    
    public static func renderSVG(latexString: String) throws -> String {
        guard let mathJax else { throw LaTeXRendererError.mathJaxUninitialized }
        var latexSVG = try mathJax.tex2svg(latexString, inputOptions: texOptions)
        
        // original:
        // <svg style="vertical-align: -0.054ex;" xmlns="http://www.w3.org/2000/svg" width="4.964ex" height="1.242ex" role="img" focusable="false" viewBox="0 -525 2194 549" ...........
        // `ex` is a relative unit and doesn't seem to be supported by CoreSVG
        // `in` is supported and makes it much more clear
        latexSVG = latexSVG.replacingOccurrences(of: "ex", with: "in")
        
        return latexSVG
    }
    
    public static func svgToImage(svgString: String, svgImageScale: CGFloat) throws -> Image {
        guard let data = svgString.data(using: .utf8) else { throw LaTeXRendererError.svgNoData }
        guard let svg = CoreSVG(data) else { throw LaTeXRendererError.couldNotCreateSVG }

        let size = CGSize(width: svg.size.width * svgImageScale, height: svg.size.height * svgImageScale)
        
        #if os(macOS)
        
        let image = NSImage(size: size)
        image.lockFocus()
        if let context = NSGraphicsContext.current?.cgContext {
            // Save the current graphics state
            context.saveGState()
              
            // Flip the coordinate system
            context.translateBy(x: 0, y: size.height)
            context.scaleBy(x: svgImageScale, y: -svgImageScale)
              
            // Draw the SVG
            svg.draw(in: context)
              
            // Restore the graphics state
            context.restoreGState()
        }
        image.unlockFocus()
        return Image(nsImage: image)
        
        #else
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            context.cgContext.scaleBy(x: svgImageScale, y: svgImageScale)
            svg.draw(in: context.cgContext)
        }
        return Image(uiImage: image)
        #endif
    }
}

