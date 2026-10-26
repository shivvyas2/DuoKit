#if os(iOS)
import DuoKitCore
import SwiftUI

/// A card grid that reflows between the outer and inner displays: one or two
/// columns folded, more when open, always an even count on the inner display,
/// and when partially folded the crease falls in a gutter, never through a card.
///
///     DuoGrid(minColumnWidth: 170) {
///         RingsRow().duoGridSpan(.full)
///         HealthCard()
///         StressCard()
///     }
public struct DuoGrid<Content: View>: View {
    private let minColumnWidth: CGFloat
    private let spacing: CGFloat
    private let maxColumns: Int?
    private let content: Content

    @Environment(\.duoLayout) private var layout
    @Environment(\.duoSimulatedFold) private var simulatedFold
    @State private var fold: ClosedRange<CGFloat>?

    public init(
        minColumnWidth: CGFloat = 160,
        spacing: CGFloat = 12,
        maxColumns: Int? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.minColumnWidth = minColumnWidth
        self.spacing = spacing
        self.maxColumns = maxColumns
        self.content = content()
    }

    public var body: some View {
        let simulatedFold = simulatedFold
        DuoGridLayout(
            minColumnWidth: minColumnWidth,
            spacing: spacing,
            maxColumns: maxColumns,
            preferEven: layout.posture.isOpen,
            fold: fold
        ) {
            content
        }
        .onGeometryChange(for: ClosedRange<CGFloat>?.self) { proxy in
            // Only a vertical crease cuts across columns.
            guard let crease = DuoProbe.fold(in: proxy, simulated: simulatedFold),
                  crease.height >= crease.width else { return nil }
            return crease.minX...crease.maxX
        } action: {
            fold = $0
        }
    }
}

public enum DuoGridSpan: Sendable {
    /// One column.
    case column
    /// The whole row, for headers, charts and hero cards.
    case full
}

public extension View {
    func duoGridSpan(_ span: DuoGridSpan) -> some View {
        layoutValue(key: DuoGridSpanKey.self, value: span)
    }
}

struct DuoGridSpanKey: LayoutValueKey {
    static let defaultValue = DuoGridSpan.column
}

struct DuoGridLayout: Layout {
    var minColumnWidth: CGFloat
    var spacing: CGFloat
    var maxColumns: Int?
    var preferEven: Bool
    var fold: ClosedRange<CGFloat>?

    /// One row of the grid: which subviews, and whether it is a full-width row.
    private struct Row {
        var indices: [Int]
        var full: Bool
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // Unspecified or infinite (a stack measuring its maximum): report the
        // two-column ideal rather than an unbounded size.
        let ideal = minColumnWidth * 2 + spacing
        let width = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? ideal
        let heights = rowHeights(width: width, subviews: subviews)
        let total = heights.reduce(0, +) + spacing * CGFloat(max(heights.count - 1, 0))
        return CGSize(width: width, height: total)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let columns = columns(width: bounds.width)
        let rows = rows(subviews: subviews, columnCount: columns.count)
        let heights = rowHeights(width: bounds.width, subviews: subviews)
        var y = bounds.minY
        for (row, height) in zip(rows, heights) {
            for (slot, index) in row.indices.enumerated() {
                let x = row.full ? 0 : columns[slot].x
                let width = row.full ? bounds.width : columns[slot].width
                subviews[index].place(
                    at: CGPoint(x: bounds.minX + x, y: y),
                    proposal: ProposedViewSize(width: width, height: height)
                )
            }
            y += height + spacing
        }
    }

    private func columns(width: CGFloat) -> [DuoColumn] {
        DuoGridMetrics.columns(
            width: width,
            minColumnWidth: minColumnWidth,
            spacing: spacing,
            preferEven: preferEven,
            maxColumns: maxColumns,
            fold: fold
        )
    }

    private func rows(subviews: Subviews, columnCount: Int) -> [Row] {
        var rows: [Row] = []
        var current: [Int] = []
        for index in subviews.indices {
            if subviews[index][DuoGridSpanKey.self] == .full {
                if !current.isEmpty { rows.append(Row(indices: current, full: false)) }
                current = []
                rows.append(Row(indices: [index], full: true))
                continue
            }
            current.append(index)
            if current.count == columnCount {
                rows.append(Row(indices: current, full: false))
                current = []
            }
        }
        if !current.isEmpty { rows.append(Row(indices: current, full: false)) }
        return rows
    }

    private func rowHeights(width: CGFloat, subviews: Subviews) -> [CGFloat] {
        let columns = columns(width: width)
        return rows(subviews: subviews, columnCount: columns.count).map { row in
            row.indices.enumerated().map { slot, index in
                let columnWidth = row.full ? width : columns[slot].width
                return subviews[index].sizeThatFits(ProposedViewSize(width: columnWidth, height: nil)).height
            }.max() ?? 0
        }
    }
}
#endif
