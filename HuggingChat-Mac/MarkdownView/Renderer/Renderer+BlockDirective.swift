import Markdown
import SwiftUI

extension Renderer {
    mutating func visitBlockDirective(_ blockDirective: BlockDirective) -> Result {
        var provider: (any BlockDirectiveDisplayable)?
        blockDirectiveRenderer.providers.forEach { name, value in
            if name.localizedLowercase == blockDirective.name.localizedLowercase {
                provider = value
            }
        }
        
        let args = blockDirective
            .argumentText
            .parseNameValueArguments()
            .map {
                BlockDirectiveArgument($0)
            }
        
        if let range = blockDirective.range {
            let bdBound = text.index(text.startIndex, offsetBy: range.lowerBound.offset(in: text)) ..< text.index(text.startIndex, offsetBy: range.upperBound.offset(in: text))
            var textInside = String(text[bdBound])
            let (lowerBound, upperBound) = (textInside.firstIndex(of: "{") ?? textInside.startIndex, textInside.lastIndex(of: "}") ?? textInside.endIndex)
            textInside = String(textInside[lowerBound..<upperBound].dropFirst())
            if let customImplementation = blockDirectiveRenderer.loadBlockDirective(provider: provider, args: args, text: textInside) {
                return Result { customImplementation }
            }
        }
        var contents = [Result]()
        for child in blockDirective.children {
            contents.append(visit(child))
        }
        return Result(contents)
    }
}
