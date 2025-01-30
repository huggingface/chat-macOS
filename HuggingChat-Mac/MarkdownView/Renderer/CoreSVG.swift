//
//  CoreSVG.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/29/25.
//

// Taken from Andrew Zheng on 7/30/24.

import CoreGraphics
import Darwin
import Foundation

// from https://gist.github.com/ollieatkinson/eb87a82fcb5500d5561fed8b0900a9f7
// https://github.com/xybp888/iOS-SDKs/blob/master/iPhoneOS17.1.sdk/System/Library/PrivateFrameworks/CoreSVG.framework/CoreSVG.tbd
// https://developer.limneos.net/index.php?ios=17.1&framework=UIKitCore.framework&header=UIImage.h

let encodedStrings = [
    "Q0dTVkdEb2N1bWVudFJldGFpbg==", // CGSVGDocumentRetain
    "Q0dTVkdEb2N1bWVudFJlbGVhc2U=", // CGSVGDocumentRelease
    "Q0dTVkdEb2N1bWVudENyZWF0ZUZyb21EYXRh", // CGSVGDocumentCreateFromData
    "Q0dDb250ZXh0RHJhd1NWR0RvY3VtZW50", // CGContextDrawSVGDocument
    "Q0dTVkdEb2N1bWVudEdldENhbnZhc1NpemU=", // CGSVGDocumentGetCanvasSize
    "L1N5c3RlbS9MaWJyYXJ5L1ByaXZhdGVGcmFtZXdvcmtzL0NvcmVTVkcuZnJhbWV3b3JrL0NvcmVTVkc=" // /System/Library/PrivateFrameworks/CoreSVG.framework/CoreSVG
]

func decodeString(_ encodedString: String) -> String {
    guard let data = Data(base64Encoded: encodedString),
          let decodedString = String(data: data, encoding: .utf8)
    else {
        return "Error decoding string"
    }
    return decodedString
}

@objc
class CGSVGDocument: NSObject {}

var CGSVGDocumentRetain: (@convention(c) (CGSVGDocument?) -> Unmanaged<CGSVGDocument>?) = load(decodeString("Q0dTVkdEb2N1bWVudFJldGFpbg=="))
var CGSVGDocumentRelease: (@convention(c) (CGSVGDocument?) -> Void) = load(decodeString("Q0dTVkdEb2N1bWVudFJlbGVhc2U="))
var CGSVGDocumentCreateFromData: (@convention(c) (CFData?, CFDictionary?) -> Unmanaged<CGSVGDocument>?) = load(decodeString("Q0dTVkdEb2N1bWVudENyZWF0ZUZyb21EYXRh"))
var CGContextDrawSVGDocument: (@convention(c) (CGContext?, CGSVGDocument?) -> Void) = load(decodeString("Q0dDb250ZXh0RHJhd1NWR0RvY3VtZW50"))
var CGSVGDocumentGetCanvasSize: (@convention(c) (CGSVGDocument?) -> CGSize) = load(decodeString("Q0dTVkdEb2N1bWVudEdldENhbnZhc1NpemU="))

let CoreSVGFramework = dlopen(decodeString("L1N5c3RlbS9MaWJyYXJ5L1ByaXZhdGVGcmFtZXdvcmtzL0NvcmVTVkcuZnJhbWV3b3JrL0NvcmVTVkc="), RTLD_NOW)

func load<T>(_ name: String) -> T {
    unsafeBitCast(dlsym(CoreSVGFramework, name), to: T.self)
}

public class CoreSVG {
    deinit { CGSVGDocumentRelease(document) }

    let document: CGSVGDocument

    public convenience init?(_ value: String) {
        guard let data = value.data(using: .utf8) else { return nil }
        self.init(data)
    }

    public init?(_ data: Data) {
        guard let document = CGSVGDocumentCreateFromData(data as CFData, nil)?.takeUnretainedValue() else { return nil }
        guard CGSVGDocumentGetCanvasSize(document) != .zero else { return nil }
        self.document = document
    }

    public var size: CGSize {
        CGSVGDocumentGetCanvasSize(document)
    }

    public func draw(in context: CGContext) {
        draw(in: context, size: size)
    }

    public func draw(in context: CGContext, size target: CGSize) {
        var target = target

        let ratio = (
            x: target.width / size.width,
            y: target.height / size.height
        )

        let rect = (
            document: CGRect(origin: .zero, size: size), ()
        )

        let scale: (x: CGFloat, y: CGFloat)

        if target.width <= 0 {
            scale = (ratio.y, ratio.y)
            target.width = size.width * scale.x
        } else if target.height <= 0 {
            scale = (ratio.x, ratio.x)
            target.width = size.width * scale.y
        } else {
            let min = min(ratio.x, ratio.y)
            scale = (min, min)
            target.width = size.width * scale.x
            target.height = size.height * scale.y
        }

        let transform = (
            scale: CGAffineTransform(scaleX: scale.x, y: scale.y),
            aspect: CGAffineTransform(translationX: (target.width / scale.x - rect.document.width) / 2, y: (target.height / scale.y - rect.document.height) / 2)
        )

        // flip for UIKit
        context.translateBy(x: 0, y: target.height)
        context.scaleBy(x: 1, y: -1)
        context.concatenate(transform.scale)
        context.concatenate(transform.aspect)

        CGContextDrawSVGDocument(context, document)
    }
}
