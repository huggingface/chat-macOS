import SwiftUI

/// A type-erased MarkdownFontGroup value.
public struct AnyMarkdownFontGroup: Sendable {
    var _h1: Font
    var _h2: Font
    var _h3: Font
    var _h4: Font
    var _h5: Font
    var _h6: Font
    var _codeBlock: Font
    var _blockQuote: Font
    var _tableHeader: Font
    var _tableBody: Font
    var _body: Font
    
    init(_ group: some MarkdownFontGroup) {
        _h1 = group.h1
        _h2 = group.h2
        _h3 = group.h3
        _h4 = group.h4
        _h5 = group.h5
        _h6 = group.h6
        _codeBlock = group.codeBlock
        _blockQuote = group.blockQuote
        _tableHeader = group.tableHeader
        _tableBody = group.tableBody
        _body = group.body
    }
}

extension AnyMarkdownFontGroup: MarkdownFontGroup {
    public var h1: Font { _h1 }
    public var h2: Font { _h2 }
    public var h3: Font { _h3 }
    public var h4: Font { _h4 }
    public var h5: Font { _h5 }
    public var h6: Font { _h6 }
    public var codeBlock: Font { _codeBlock }
    public var blockQuote: Font { _blockQuote }
    public var tableHeader: Font { _tableHeader }
    public var tableBody: Font { _tableBody }
    public var body: Font { _body }
}

extension AnyMarkdownFontGroup: Equatable { }
