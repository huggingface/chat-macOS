import SwiftUI

/// An adaptive grid that dynamically adjust column width to best fit the content.
struct AdaptiveGrid: View {
    var rows: [GridRowContainer]
    var horizontalSpacing: CGFloat?
    var verticalSpacing: CGFloat?
    var showDivider: Bool
    
    private var columnsCount: Int
    // The width of each cell.
    @State private var cellSize: [CGFloat]
    // The width of each column
    @State private var colWidth: [CGFloat]
    @State private var height = CGFloat.zero
    // The width of the whole table
    @State private var _width = CGFloat.zero
    
    /// Create an adaptive grid that dynamically adjust column width to best fit the content.
    /// - Parameters:
    ///   - horizontalSpacing: The spacing between two elements in the x axis.
    ///   - verticalSpacing: The spacing between two elements in the y axis.
    ///   - showDivider: Whether to show dividers between rows.
    ///   - content: The content container of the grid.
    init(horizontalSpacing: CGFloat? = nil, verticalSpacing: CGFloat? = nil, showDivider: Bool = false, content: GridContainer) {
        self.rows = content.rows
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.showDivider = showDivider
        
        columnsCount = self.rows.reduce(0) { max($1.count, $0) }
        let sizes = [CGFloat](repeating: .zero, count: self.rows.count * columnsCount)
        // Save widths of all cells and calculate relative width for each column
        _cellSize = State(initialValue: sizes)
        _colWidth = State(initialValue: [CGFloat](repeating: .zero, count: columnsCount))
    }
    
    /// Create an adaptive grid that dynamically adjust column width to best fit the content.
    /// - Parameters:
    ///   - horizontalSpacing: The spacing between two elements in the x axis.
    ///   - verticalSpacing: The spacing between two elements in the y axis.
    ///   - showDivider: Whether to show dividers between rows.
    ///   - content: A closure that creates the grid’s rows.
    init(horizontalSpacing: CGFloat? = nil, verticalSpacing: CGFloat? = nil, showDivider: Bool = false, @GridBuilder content: () -> GridContainer) {
        self.rows = content().rows
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.showDivider = showDivider
        
        columnsCount = self.rows.reduce(0) { max($1.count, $0) }
        let sizes = [CGFloat](repeating: .zero, count: self.rows.count * columnsCount)
        // Save widths of all cells and calculate relative width for each column
        _cellSize = State(initialValue: sizes)
        _colWidth = State(initialValue: [CGFloat](repeating: .zero, count: columnsCount))
    }
    
    var body: some View {
        GeometryReader { geometryProxy in
            tableBody
                .heightOfView($height)
                ._task(id: geometryProxy.size) {
                    _width = geometryProxy.size.width
                    updateLayout()
                }
        }
        .frame(height: height)
    }
    
    private var tableBody: some View {
        VStack(spacing: verticalSpacing) {
            ForEach(rows.indices, id: \.self) { row in
                AdaptiveGridRow(
                    row: rows[row],
                    columnWidth: colWidth,
                    spacing: horizontalSpacing
                ) { col, width in
                    // Update width of cells
                    cellSize[row * columnsCount + col] = width
                    updateLayout()
                }
                if showDivider && rows.count - 1 != row {
                    Divider()
                }
            }
        }
    }
    
    // Re-calculate column width for table.
    private func updateLayout() {
        var colWidth = [CGFloat](repeating: .zero, count: columnsCount)
        for (index, size) in cellSize.enumerated() {
            let col = index % columnsCount // [0, (columnsCount - 1)] Represents the column index.
            if colWidth[col] < size {
                colWidth[col] = size
            }
        }
        let spacing = max(0, (_width - colWidth.reduce(0, +)) / CGFloat(columnsCount))
        self.colWidth = colWidth.map {
            $0 + spacing
        }
//        print("Spacing: \(spacing)")
//        print("Cell Width: \(colWidth)")
//        print("Avg spacing: \(spacing)")
//        print("--------")
    }
}

struct AdaptiveGrid_Previews: PreviewProvider {
    static let grid = GridContainer {
        GridRowContainer {
            GridCellContainer {
                Text("Cell")
            }
            GridCellContainer(alignment: .leading) {
                Text("Leading")
            }
        }
        GridRowContainer {
            GridCellContainer {
                Text("Cell")
            }
        }
    }
    
    static var previews: some View {
        AdaptiveGrid(content: grid)
    }
}
