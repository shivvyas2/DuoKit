import CoreGraphics

public struct DuoColumn: Equatable, Sendable {
    public var x: CGFloat
    public var width: CGFloat

    public init(x: CGFloat, width: CGFloat) {
        self.x = x
        self.width = width
    }
}

/// Column maths for grids that reflow between the outer and inner displays.
///
/// HIG: preserve outer margins, prefer an even number of columns on the inner
/// display, and add space around the hinge so no card straddles the fold.
public enum DuoGridMetrics {
    public static func columnCount(
        width: CGFloat,
        minColumnWidth: CGFloat,
        spacing: CGFloat,
        preferEven: Bool = false,
        maxColumns: Int? = nil
    ) -> Int {
        let fit = ((width + spacing) / (minColumnWidth + spacing)).rounded(.down)
        // Stacks probe with an infinite width; take as many as allowed.
        var count = fit.isFinite ? Int(fit) : (fit == .infinity ? (maxColumns ?? 1) : 1)
        if let maxColumns { count = min(count, maxColumns) }
        count = max(count, 1)
        if preferEven, count > 1, count % 2 == 1 { count -= 1 }
        return count
    }

    /// Column positions across `width`.
    ///
    /// When a crease (`fold`, in the grid's own x coordinates) crosses the
    /// grid, each side gets as many columns as fit on it and the crease sits
    /// in the gutter. A side too narrow for one column stays empty: a grid
    /// beside a sidebar often has the crease just inside its leading edge.
    public static func columns(
        width: CGFloat,
        minColumnWidth: CGFloat,
        spacing: CGFloat,
        preferEven: Bool = false,
        maxColumns: Int? = nil,
        fold: ClosedRange<CGFloat>? = nil
    ) -> [DuoColumn] {
        if let fold, fold.lowerBound > 0, fold.upperBound < width {
            let half = spacing / 2
            let leftEnd = fold.lowerBound - half
            let rightStart = fold.upperBound + half
            var left = fitting(leftEnd, minColumnWidth: minColumnWidth, spacing: spacing)
            var right = fitting(width - rightStart, minColumnWidth: minColumnWidth, spacing: spacing)
            if let maxColumns {
                while left + right > max(maxColumns, 1) {
                    if left >= right { left -= 1 } else { right -= 1 }
                }
            }
            if left + right > 0 {
                return evenly(from: 0, to: leftEnd, count: left, spacing: spacing)
                    + evenly(from: rightStart, to: width, count: right, spacing: spacing)
            }
        }
        let count = columnCount(
            width: width,
            minColumnWidth: minColumnWidth,
            spacing: spacing,
            preferEven: preferEven,
            maxColumns: maxColumns
        )
        return evenly(from: 0, to: width, count: count, spacing: spacing)
    }

    private static func fitting(_ width: CGFloat, minColumnWidth: CGFloat, spacing: CGFloat) -> Int {
        guard width >= minColumnWidth else { return 0 }
        let fit = ((width + spacing) / (minColumnWidth + spacing)).rounded(.down)
        return fit.isFinite ? Int(fit) : 1
    }

    private static func evenly(from start: CGFloat, to end: CGFloat, count: Int, spacing: CGFloat) -> [DuoColumn] {
        guard count > 0 else { return [] }
        let columnWidth = max(0, (end - start - spacing * CGFloat(count - 1)) / CGFloat(count))
        return (0..<count).map { i in
            DuoColumn(x: start + CGFloat(i) * (columnWidth + spacing), width: columnWidth)
        }
    }
}
