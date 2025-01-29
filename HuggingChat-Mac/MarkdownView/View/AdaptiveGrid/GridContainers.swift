import SwiftUI

// MARK: - Grid

struct GridContainer {
    var rows: [GridRowContainer]
    var cells: [GridCellContainer] {
        rows.lazy.flatMap { $0.cells }
    }
    
    init(rows: [GridRowContainer]) {
        self.rows = rows
    }
}

extension GridContainer {
     init(@GridBuilder _ grid: () -> GridContainer) {
        self = grid()
    }
}

@resultBuilder struct GridBuilder {
    static func buildBlock(_ grids: GridContainer...) -> GridContainer {
        var container = GridContainer(rows: [])
        for grid in grids {
            container.rows.append(contentsOf: grid.rows)
        }
        return container
    }
    static func buildExpression(_ row: GridRowContainer) -> GridContainer {
        GridContainer(rows: [row])
    }
    static func buildArray(_ grids: [GridContainer]) -> GridContainer {
        GridContainer(rows: grids.flatMap { $0.rows })
    }
}

// MARK: - Grid Row

protocol GridRowProtocol {
    var cells: [GridCellContainer] { get }
}

struct GridRowContainer: GridRowProtocol {
    var cells: [GridCellContainer]
    var count: Int { cells.count }
    
    init(cells: [GridCellContainer]) {
        self.cells = cells
    }
}

extension GridRowContainer {
    init(@GridRowBuilder _ row: () -> GridRowContainer) {
        self = row()
    }
}

@resultBuilder struct GridRowBuilder {
    static func buildBlock(_ components: GridRowContainer...) -> GridRowContainer {
        var container = GridRowContainer(cells: [])
        for component in components {
            container.cells.append(contentsOf: component.cells)
        }
        return container
    }
    static func buildExpression(_ cell: GridCellContainer) -> GridRowContainer {
        GridRowContainer(cells: [cell])
    }
    static func buildExpression(_ cells: [GridCellContainer]) -> GridRowContainer {
        GridRowContainer(cells: cells)
    }
    static func buildArray(_ components: [GridRowContainer]) -> GridRowContainer {
        GridRowContainer(cells: components.flatMap { $0.cells })
    }
    static func buildExpression(_ expression: some View) -> GridRowContainer {
        GridRowContainer(cells: [GridCellContainer(content: expression)])
    }
}

// MARK: - Grid Cell

struct GridCellContainer: Identifiable {
    var id = UUID()
    var alignment: HorizontalAlignment
    var content: AnyView
    
    init(alignment: HorizontalAlignment = .center, @ViewBuilder content: () -> some View) {
        self.alignment = alignment
        self.content = AnyView(content())
    }
    
    init(alignment: HorizontalAlignment = .center, content: some View) {
        self.alignment = alignment
        self.content = AnyView(content)
    }
}
