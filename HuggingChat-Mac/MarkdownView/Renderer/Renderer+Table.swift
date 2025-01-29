import SwiftUI
import Markdown

extension Renderer {
    @MainActor
    mutating func visitTable(_ table: Markdown.Table) -> Result {
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            return Result {
                Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                    GridRow { visitTableHead(table.head).content }
                    visitTableBody(table.body).content
                }
                .modifier(_TableViewModifier())
            }
        } else {
            let headRow = GridRowContainer {
                table.head.children.map { cell in
                    GridCellContainer(alignment: (cell as! Markdown.Table.Cell).alignment) {
                        visit(cell).content
                            .font(configuration.fontGroup.tableHeader)
                            .foregroundStyle(configuration.foregroundStyleGroup.tableHeader)
                    }
                }
            }
            let bodyRows = table.body.children.map { row in
                GridRowContainer {
                    row.children.map { cell in
                        GridCellContainer(alignment: (cell as! Markdown.Table.Cell).alignment) {
                            visit(cell).content
                                .font(configuration.fontGroup.tableBody)
                                .foregroundStyle(configuration.foregroundStyleGroup.tableBody)
                        }
                    }
                }
            }
            return Result {
                AdaptiveGrid(showDivider: true) {
                    headRow
                    for bodyRow in bodyRows {
                        bodyRow
                    }
                }
                .modifier(_TableViewModifier())
            }
        }
    }
    
    mutating func visitTableHead(_ head: Markdown.Table.Head) -> Result {
        Result {
            let contents = contents(of: head)
            let font = configuration.fontGroup.tableHeader
            let foregroundStyle = configuration.foregroundStyleGroup.tableHeader
            ForEach(contents.indices, id: \.self) {
                contents[$0].content
                    .font(font)
                    .foregroundStyle(foregroundStyle)
            }
        }
    }
    
    mutating func visitTableBody(_ body: Markdown.Table.Body) -> Result {
        Result {
            let contents = contents(of: body)
            let font = configuration.fontGroup.tableBody
            let foregroundStyle = configuration.foregroundStyleGroup.tableBody
            ForEach(contents.indices, id: \.self) {
                Divider()
                contents[$0].content
                    .font(font)
                    .foregroundStyle(foregroundStyle)
            }
        }
    }
    
    @MainActor
    mutating func visitTableRow(_ row: Markdown.Table.Row) -> Result {
        Result {
            let cells = row.children.map { $0 as! Markdown.Table.Cell }
            let contents = cells.map { visitTableCell($0) }
            if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
                GridRow {
                    ForEach(contents.indices, id: \.self) { index in
                        let tableCell = cells[index]
                        contents[index].content
                            .gridColumnAlignment(tableCell.alignment)
                            .gridCellColumns(Int(tableCell.colspan))
                    }
                }
            }
        }
    }
    
    mutating func visitTableCell(_ cell: Markdown.Table.Cell) -> Result {
        Result(contents(of: cell), alignment: cell.alignment)
    }
}

// MARK: - Table Style

fileprivate struct _TableViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scenePadding()
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.quaternary, lineWidth: 2)
            }
    }
}

