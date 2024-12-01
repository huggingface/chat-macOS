//
//  AverageColor.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 11/30/24.
//

import Foundation
import SwiftUI

enum AverageColorAlgorithm {
    case simple
    case squareRoot
}

func findAverageColor(cgImage: CGImage, algorithm: AverageColorAlgorithm = .simple) -> Color? {
    // First, resize the image. We do this for two reasons, 1) less pixels to deal with means faster calculation and a resized image still has the "gist" of the colors, and 2) the image we're dealing with may come in any of a variety of color formats (CMYK, ARGB, RGBA, etc.) which complicates things, and redrawing it normalizes that into a base color format we can deal with.
    // 40x40 is a good size to resize to still preserve quite a bit of detail but not have too many pixels to deal with. Aspect ratio is irrelevant for just finding average color.
    let size = CGSize(width: 40, height: 40)
    
    let width = Int(size.width)
    let height = Int(size.height)
    let totalPixels = width * height
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    // ARGB format
    let bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
    
    // 8 bits for each color channel, we're doing ARGB so 32 bits (4 bytes) total, and thus if the image is n pixels wide, and has 4 bytes per pixel, the total bytes per row is 4n. That gives us 2^8 = 256 color variations for each RGB channel or 256 * 256 * 256 = ~16.7M color options in total. That seems like a lot, but lots of HDR movies are in 10 bit, which is (2^10)^3 = 1 billion color options!
    guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: bitmapInfo) else { return nil }
    
    // Draw our resized image
    context.draw(cgImage, in: CGRect(origin: .zero, size: size))
    
    guard let pixelBuffer = context.data else { return nil }
    
    // Bind the pixel buffer's memory location to a pointer we can use/access
    let pointer = pixelBuffer.bindMemory(to: UInt32.self, capacity: width * height)
    
    // Keep track of total colors (note: we don't care about alpha and will always assume alpha of 1, AKA opaque)
    var totalRed = 0
    var totalBlue = 0
    var totalGreen = 0
    
    // Column of pixels in image
    for x in 0 ..< width {
        // Row of pixels in image
        for y in 0 ..< height {
            // To get the pixel location just think of the image as a grid of pixels, but stored as one long row rather than columns and rows, so for instance to map the pixel from the grid in the 15th row and 3 columns in to our "long row", we'd offset ourselves 15 times the width in pixels of the image, and then offset by the amount of columns
            let pixel = pointer[(y * width) + x]
            
            let r = red(for: pixel)
            let g = green(for: pixel)
            let b = blue(for: pixel)
            
            switch algorithm {
            case .simple:
                totalRed += Int(r)
                totalBlue += Int(b)
                totalGreen += Int(g)
            case .squareRoot:
                totalRed += Int(pow(CGFloat(r), CGFloat(2)))
                totalGreen += Int(pow(CGFloat(g), CGFloat(2)))
                totalBlue += Int(pow(CGFloat(b), CGFloat(2)))
            }
        }
    }
    
    let averageRed: CGFloat
    let averageGreen: CGFloat
    let averageBlue: CGFloat
    
    switch algorithm {
    case .simple:
        averageRed = CGFloat(totalRed) / CGFloat(totalPixels)
        averageGreen = CGFloat(totalGreen) / CGFloat(totalPixels)
        averageBlue = CGFloat(totalBlue) / CGFloat(totalPixels)
    case .squareRoot:
        averageRed = sqrt(CGFloat(totalRed) / CGFloat(totalPixels))
        averageGreen = sqrt(CGFloat(totalGreen) / CGFloat(totalPixels))
        averageBlue = sqrt(CGFloat(totalBlue) / CGFloat(totalPixels))
    }
    
    // Convert from [0 ... 255] format to the [0 ... 1.0] format UIColor wants
    return Color(red: averageRed / 255.0, green: averageGreen / 255.0, blue: averageBlue / 255.0)
}

private func red(for pixelData: UInt32) -> UInt8 {
    // For a quick primer on bit shifting and what we're doing here, in our ARGB color format image each pixel's colors are stored as a 32 bit integer, with 8 bits per color chanel (A, R, G, and B).
    //
    // So a pure red color would look like this in bits in our format, all red, no blue, no green, and 'who cares' alpha:
    //
    // 11111111 11111111 00000000 00000000
    //  ^alpha   ^red     ^blue    ^green
    //
    // We want to grab only the red channel in this case, we don't care about alpha, blue, or green. So we want to shift the red bits all the way to the right in order to have them in the right position (we're storing colors as 8 bits, so we need the right most 8 bits to be the red). Red is 16 points from the right, so we shift it by 16 (for the other colors, we shift less, as shown below).
    //
    // Just shifting would give us:
    //
    // 00000000 00000000 11111111 11111111
    //  ^alpha   ^red     ^blue    ^green
    //
    // The alpha got pulled over which we don't want or care about, so we need to get rid of it. We can do that with the bitwise AND operator (&) which compares bits and the only keeps a 1 if both bits being compared are 1s. So we're basically using it as a gate to only let the bits we want through. 255 (below) is the value we're using as in binary it's 11111111 (or in 32 bit, it's 00000000 00000000 00000000 11111111) and the result of the bitwise operation is then:
    //
    // 00000000 00000000 11111111 11111111
    // 00000000 00000000 00000000 11111111
    // -----------------------------------
    // 00000000 00000000 00000000 11111111
    //
    // So as you can see, it only keeps the last 8 bits and 0s out the rest, which is what we want! Woohoo! (It isn't too exciting in this scenario, but if it wasn't pure red and was instead a red of value "11010010" for instance, it would also mirror that down)
    return UInt8((pixelData >> 16) & 255)
}

private func green(for pixelData: UInt32) -> UInt8 {
    return UInt8((pixelData >> 8) & 255)
}

private func blue(for pixelData: UInt32) -> UInt8 {
    return UInt8((pixelData >> 0) & 255)
}


extension View {
    /// Usually you would pass  `@Environment(\.displayScale) var displayScale`
    @MainActor func render(scale displayScale: CGFloat = 1.0) -> CGImage? {
        let renderer = ImageRenderer(content: self)

        renderer.scale = displayScale
        
        return renderer.cgImage
    }
    
}
