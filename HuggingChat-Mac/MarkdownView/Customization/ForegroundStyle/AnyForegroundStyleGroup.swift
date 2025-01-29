import SwiftUI

/// A type-erased MarkdownForegroundStyleGroup value.
public struct AnyMarkdownForegroundStyleGroup: Sendable {
    var _h1: AnyShapeStyle
    var _h2: AnyShapeStyle
    var _h3: AnyShapeStyle
    var _h4: AnyShapeStyle
    var _h5: AnyShapeStyle
    var _h6: AnyShapeStyle
    var _codeBlock: AnyShapeStyle
    var _blockQuote: AnyShapeStyle
    var _tableHeader: AnyShapeStyle
    var _tableBody: AnyShapeStyle
    
    init(_ group: some MarkdownForegroundStyleGroup) {
        _h1 = AnyShapeStyle(group.h1)
        _h2 = AnyShapeStyle(group.h2)
        _h3 = AnyShapeStyle(group.h3)
        _h4 = AnyShapeStyle(group.h4)
        _h5 = AnyShapeStyle(group.h5)
        _h6 = AnyShapeStyle(group.h6)
        _codeBlock = AnyShapeStyle(group.codeBlock)
        _blockQuote = AnyShapeStyle(group.blockQuote)
        _tableHeader = AnyShapeStyle(group.tableHeader)
        _tableBody = AnyShapeStyle(group.tableBody)
    }
}

extension AnyMarkdownForegroundStyleGroup: MarkdownForegroundStyleGroup {
    public var h1: AnyShapeStyle { _h1 }
    public var h2: AnyShapeStyle { _h2 }
    public var h3: AnyShapeStyle { _h3 }
    public var h4: AnyShapeStyle { _h4 }
    public var h5: AnyShapeStyle { _h5 }
    public var h6: AnyShapeStyle { _h6 }
    public var codeBlock: AnyShapeStyle { _codeBlock }
    public var blockQuote: AnyShapeStyle { _blockQuote }
    public var tableHeader: AnyShapeStyle { _tableHeader }
    public var tableBody: AnyShapeStyle { _tableBody }
}

extension AnyMarkdownForegroundStyleGroup: Equatable { }
