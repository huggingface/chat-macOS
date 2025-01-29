import SwiftUI
import Markdown

struct Renderer: @preconcurrency MarkupVisitor {
    typealias Result = ViewContent
    
    var text: String
    var configuration: RendererConfiguration
    // Handle text changes when toggle checkmarks.
    var interactiveEditHandler: (String) -> Void
    
    var blockDirectiveRenderer: BlockDirectiveRenderer
    var imageRenderer: ImageRenderer
    
    mutating func representedView(parseBlockDirectives: Bool) -> AnyView {
        let options: ParseOptions = parseBlockDirectives ? [.parseBlockDirectives] : []
        return visit(Document(parsing: text, options: options)).content.eraseToAnyView()
    }
    
    mutating func visitDocument(_ document: Document) -> Result {
        let contents = contents(of: document)
        var paras = [Result]()
        var index = 0
        while index < contents.count {
            if contents[index].type == .text && paras.last?.type == .text {
                paras.append(Result(Text("\n\n") + contents[index].text))
            } else {
                paras.append(contents[index])
            }
            index += 1
        }
        return Result(paras, autoLayout: false)
    }
    
    mutating func defaultVisit(_ markup: Markdown.Markup) -> Result {
        Result(contents(of: markup))
    }
    
    mutating func visitText(_ text: Markdown.Text) -> Result {
        Result(SwiftUI.Text(text.plainText))
    }
    
    mutating func visitParagraph(_ paragraph: Paragraph) -> Result {
        Result(contents(of: paragraph))
    }

    mutating func visitLink(_ link: Markdown.Link) -> Result {
        var contents = [Result]()
        var isText = true
        for child in link.children {
            let content = visit(child)
            contents.append(content)
            if content.type == .view {
                isText = false
            }
        }
        if isText {
            var attributer = LinkAttributer(
                tint: configuration.inlineCodeTintColor,
                font: configuration.fontGroup.body
            )
            let link = attributer.visit(link)
            return Result(SwiftUI.Text(link))
        } else {
            return Result(contents)
        }
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> Result {
        Result {
            let contents = contents(of: blockQuote)
            VStack(alignment: .leading, spacing: configuration.componentSpacing) {
                ForEach(contents.indices, id: \.self) { index in
                    contents[index].content
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(configuration.fontGroup.blockQuote)
            .padding(.horizontal, 20)
            .background {
                configuration.blockQuoteTintColor
                    .opacity(0.1)
            }
            .overlay(alignment: .leading) {
                configuration.blockQuoteTintColor
                    .frame(width: 4)
            }
            .cornerRadius(3)
        }
    }

    mutating func visitImage(_ image: Markdown.Image) -> Result {
        guard let source = URL(string: image.source ?? "") else {
            return Result(SwiftUI.Text(image.plainText))
        }

        let alt: String?
        if !(image.parent is Markdown.Link) {
            if let title = image.title, !title.isEmpty {
                alt = title
            } else {
                alt = image.plainText.isEmpty ? nil : image.plainText
            }
        } else {
            // If the image is inside a link, then ignore the alternative text
            alt = nil
        }
        
        var provider: (any ImageDisplayable)?
        if let scheme = source.scheme {
            imageRenderer.imageProviders.forEach { key, value in
                if scheme.localizedLowercase == key.localizedLowercase {
                    provider = value
                    return
                }
            }
        }
        
        return Result(imageRenderer.loadImage(provider, url: source, alt: alt))
    }
}

// MARK: - Extensions

extension ListItemContainer {
    /// Depth of the list if nested within others. Index starts at 0.
    var listDepth: Int {
        var index = 0

        var currentElement = parent

        while currentElement != nil {
            if currentElement is ListItemContainer {
                index += 1
            }

            currentElement = currentElement?.parent
        }
        
        return index
    }
}

extension BlockQuote {
    /// Depth of the quote if nested within others. Index starts at 0.
    var quoteDepth: Int {
        var index = 0

        var currentElement = parent

        while currentElement != nil {
            if currentElement is BlockQuote {
                index += 1
            }

            currentElement = currentElement?.parent
        }
        
        return index
    }
}

extension Markup {
    /// Returns true if this element has sibling elements after it.
    var hasSuccessor: Bool {
        guard let childCount = parent?.childCount else { return false }
        return indexInParent < childCount - 1
    }
    
    var isContainedInList: Bool {
        var currentElement = parent

        while currentElement != nil {
            if currentElement is ListItemContainer {
                return true
            }

            currentElement = currentElement?.parent
        }
        
        return false
    }
}

extension BasicInlineContainer {
    var alignment: HorizontalAlignment {
        guard parent is any TableCellContainer else { return .center }
        
        let columnIdx = self.indexInParent
        var currentElement = parent
        while currentElement != nil {
            if currentElement is Markdown.Table {
                let alignment = (currentElement as! Markdown.Table).columnAlignments[columnIdx]
                switch alignment {
                case .center: return .center
                case .left: return .leading
                case .right: return .trailing
                case .none: return .leading
                }
            }

            currentElement = currentElement?.parent
        }
        return .center
    }
}


extension Renderer {
    mutating func contents(of markup: Markup) -> [Result] {
        markup.children.map { visit($0) }
    }
}
