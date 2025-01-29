#if os(macOS) || os(iOS)
import SwiftUI
import Markdown

/// A TOC Menu that shows all headings.
///
/// Extracts the TOC from text and scroll to selected heading.
public struct TOCMenu<Label: View>: View {
    private var animation = false
    @ViewBuilder private var label: () -> Label
    
    /// Stored markdown text.
    ///
    /// The value is only available after `MarkdownView` has been initialized.
    ///
    /// - note: If you still want to show TOC Menu, you should manually set `markdown` when you initiate a TOCMenu.
    @StateObject private var textStorage = MarkdownTextStorage.default
    private var proxyRef = ScrollProxyRef.shared
    
    /// Initiate a TOC Menu.
    /// - Parameters:
    ///   - markdown: Markdown text, this is needed when MarkdownView hasn't appear.
    ///   - animated: `true` to animate scrolling or false to scroll content without animations.
    public init(markdown: String? = nil, animated: Bool = false) where Label == SwiftUI.Label<SwiftUI.Text, SwiftUI.Image> {
        self.animation = animated
        self.label = { SwiftUI.Label("TOC", systemImage: "filemenu.and.selection") }
        if let markdown {
            Task { @MainActor in
                MarkdownTextStorage.default.text = markdown
            }
        }
    }
    
    /// Initiate a TOC Menu.
    /// - Parameters:
    ///   - text: Markdown text, typically the same to the text in MarkdownView.
    ///   - animated: `true` to animate scrolling or false to scroll content without animations.
    ///   - label: Custom label for the Menu.
    public init(markdown: String? = nil, animated: Bool = false, @ViewBuilder label: @escaping () -> Label) {
        self.animation = animated
        self.label = label
        if let markdown {
            Task { @MainActor in
                MarkdownTextStorage.default.text = markdown
            }
        }
    }
    
    public var body: some View {
        Menu {
            if let text = textStorage.text {
                var extractor = TOCExtractor()
                let sections = extractor.extract(from: text)
                ForEach(sections, id: \.self) { section in
                    Button {
                        let id = section.range?.description ?? "Unknown Range"
                        withAnimation(self.animation ? .default : nil) {
                            proxyRef.proxy?.scrollTo(id, anchor: UnitPoint(x: 0, y: 0.15))
                        }
                    } label: {
                        Text(section.markdown)
                    }
                    Divider()
                }
                .buttonStyle(.borderless)
            }
        } label: {
            label()
        }
    }
}

struct TOCExtractor: MarkupWalker {
    private var sections = [TOCItem]()
    
    mutating func extract(from text: String) -> [TOCItem] {
        let document = Document(parsing: text)
        self.visit(document)
        return sections
    }
    
    mutating func visitHeading(_ heading: Markdown.Heading) {
        sections.append(TOCItem(level: heading.level, range: heading.range, plainText: heading.plainText))
        descendInto(heading)
    }
    
    struct TOCItem: Hashable {
        /// Heading level, starting from 1.
        var level: Int
        /// The range of the heading in the raw Markdown.
        var range: SourceRange?
        /// The content text of the heading.
        var plainText: String
        
        var markdown: String {
            var markdownText = [String](repeating: "   ", count: level - 1).joined()
            for _ in 1...level {
                markdownText.append("#")
            }
            markdownText.append(" \(plainText)")
            return markdownText
        }
    }
}
#endif
