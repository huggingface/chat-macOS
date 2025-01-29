import SwiftUI

struct AdaptiveGridRow: View {
    var row: GridRowContainer
    var columnWidth: [CGFloat]
    var spacing: CGFloat?
    // Update cell width when detected
    var sizeOnChange: (_ col: Int, _ width: CGFloat) -> Void
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(row.cells.indices, id: \.self) { col in
                let cell = row.cells[col]
                let alignment = Alignment(horizontal: cell.alignment, vertical: .center)
                
                cell.content
                    .id(cell.id)
                    .frame(maxWidth: columnWidth[col], alignment: alignment)
            }
            if row.count < columnsCount {
                ForEach(row.count..<columnsCount, id: \.self) { index in
                    Color.clear
                        .frame(maxWidth: columnWidth[index])
                        .frame(height: 1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        ._overlay { sizeDetector }
    }
    
    private var columnsCount: Int { columnWidth.count }
    
    private var sizeDetector: some View {
        HStack {
            ForEach(row.cells.indices, id: \.self) { col in
                let cell = row.cells[col]
                cell.content
                    .id(cell.id)
                    .onWidthChange { sizeOnChange(col, $0) }
            }
        }
        .hidden()
    }
}
