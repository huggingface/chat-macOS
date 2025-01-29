import SwiftUI

struct ViewContent: @unchecked Sendable {
    var text: Text
    var view: AnyView
    var type: ContentType
    
    enum ContentType: String {
        case text, view
    }
    
    @ViewBuilder var content: some View {
        Group {
            switch self.type {
            case .text: self.text
            case .view: self.view
            }
        }
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
    }
    
    /// Create a content descriptor.
    /// - Parameter content: A SwiftUI Text.
    init(_ content: Text) {
        text = content
        view = AnyView(EmptyView())
        type = .text
    }
    
    /// Create a content descriptor.
    /// - Parameter content: Any view that comforms to View protocol.
    
    init(_ content: some View) {
        text = Text("")
        view = AnyView(content)
        type = .view
    }
}

// MARK: Initialize with SwiftUI Text
extension ViewContent {
    /// Create a content descriptor from a set of Text.
    /// - Parameter multiText: A set of SwiftUI Text.
    init(_ multiText: [Text]) {
        type = .text
        view = AnyView(EmptyView())
        self.text = Text(verbatim: "")
        for partialText in multiText {
            self.text = self.text + partialText
        }
    }
}

// MARK: Initialize with Views
extension ViewContent {
    /// Create a content descriptor using trailing closure.
    /// - Parameter content: The view to add to the descriptor.
    init<V: View>(@ViewBuilder _ content: () -> V) {
        text = Text("")
        view = AnyView(content())
        type = .view
    }
}

extension ViewContent {
    /// Combine adjacent views of the same type.
    /// - Parameter contents: A set of contents to combine together.
    /// - Parameter alignment: The alignment in relation to these contents.
    init(_ contents: [ViewContent], alignment: HorizontalAlignment = .leading, autoLayout: Bool = true) {
        var composedContents = [ViewContent]()
        var text = [Text]()
        for content in contents {
            if content.type == .text {
                text.append(content.text)
            } else {
                if !text.isEmpty {
                    composedContents.append(ViewContent(text))
                    text.removeAll()
                }
                composedContents.append(ViewContent(content.view))
            }
        }
        if !text.isEmpty {
            composedContents.append(ViewContent(text))
        }
        
        // Only contains text
        if composedContents.count == 1 {
            self = composedContents[0]
        } else {
            if #available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *), autoLayout {
                let composedView = FlowLayout(verticleSpacing: 8) {
                    ForEach(composedContents.indices, id: \.self) {
                        composedContents[$0].content
                    }
                }
                view = AnyView(composedView)
            } else {
                let composedView = VStack(alignment: alignment, spacing: 8) {
                    ForEach(composedContents.indices, id: \.self) {
                        composedContents[$0].content
                    }
                }
                view = AnyView(composedView)
            }
            type = .view
            self.text = Text(verbatim: "")
        }
    }
}

extension View {
    nonisolated func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}
