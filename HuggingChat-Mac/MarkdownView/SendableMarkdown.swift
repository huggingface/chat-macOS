import Markdown

// TODO: Remove these when swift-markdown adapted for swift 6.0
extension Markdown.Table: @retroactive @unchecked Sendable { }
extension Markdown.Table.Row: @retroactive @unchecked Sendable { }
extension Markdown.OrderedList: @retroactive @unchecked Sendable { }
extension Markdown.UnorderedList: @retroactive @unchecked Sendable { }
extension Markdown.ParseOptions: @retroactive @unchecked Sendable { }
