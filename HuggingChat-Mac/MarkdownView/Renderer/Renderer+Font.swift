import Markdown
import SwiftUI

extension Renderer {
    mutating func visitEmphasis(_ emphasis: Markdown.Emphasis) -> Result {
        var text = [SwiftUI.Text]()
        for child in emphasis.children {
            text.append(visit(child).text.italic())
        }
        return Result(text)
    }
    
    mutating func visitStrong(_ strong: Strong) -> Result {
        var text = [SwiftUI.Text]()
        for child in strong.children {
            text.append(visit(child).text.bold())
        }
        return Result(text)
    }
    
    mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> Result {
        var text = [SwiftUI.Text]()
        for child in strikethrough.children {
            text.append(visit(child).text.strikethrough())
        }
        return Result(text)
    }
    
    mutating func visitHeading(_ heading: Heading) -> Result {
        let fontProvider = configuration.fontGroup
        let font: Font
        switch heading.level {
        case 1: font = fontProvider.h1
        case 2: font = fontProvider.h2
        case 3: font = fontProvider.h3
        case 4: font = fontProvider.h4
        case 5: font = fontProvider.h5
        case 6: font = fontProvider.h6
        default: font = fontProvider.body
        }
        
        let styleProvider = configuration.foregroundStyleGroup
        let foregroundStyle: AnyShapeStyle
        switch heading.level {
        case 1: foregroundStyle = styleProvider.h1
        case 2: foregroundStyle = styleProvider.h2
        case 3: foregroundStyle = styleProvider.h3
        case 4: foregroundStyle = styleProvider.h4
        case 5: foregroundStyle = styleProvider.h5
        case 6: foregroundStyle = styleProvider.h6
        default: foregroundStyle = AnyShapeStyle(.foreground)
        }
        
        var text = SwiftUI.Text("")
        for child in heading.children {
            text = text + visit(child).text.font(font)
        }
        let index = heading.indexInParent
        let id = heading.range?.description ?? "Unknown Range"
        if index - 1 >= 0,
           heading.parent?.child(at: index - 1) is Heading {
            // If the previous markup is `Heading`, do not add spacing to the top.
            return Result(text.id(id).foregroundStyle(foregroundStyle).accessibilityAddTraits(.isHeader))
        }
        // Otherwise, add spacing to the top of the text to make the heading text stand out.
        return Result(
            text.id(id).padding(.top).foregroundStyle(foregroundStyle).accessibilityAddTraits(.isHeader)
        )
    }
}
