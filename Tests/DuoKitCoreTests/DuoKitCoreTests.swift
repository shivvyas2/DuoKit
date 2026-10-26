import CoreGraphics
import Testing
@testable import DuoKitCore

@Suite struct PostureTests {
    @Test func compactWidthIsCompact() {
        #expect(DuoPosture.resolve(horizontal: .compact, vertical: .regular) == .compact)
        #expect(DuoPosture.resolve(horizontal: .compact, vertical: .compact) == .compact)
    }

    @Test func regularBothWaysIsExpanded() {
        #expect(DuoPosture.resolve(horizontal: .regular, vertical: .regular) == .expanded)
        #expect(DuoPosture.resolve(horizontal: .regular, vertical: .regular, hinge: .fullyOpen) == .expanded)
    }

    @Test func partiallyOpenWithVerticalCreaseIsBook() {
        let fold = CGRect(x: 390, y: 0, width: 20, height: 900)
        #expect(DuoPosture.resolve(horizontal: .regular, vertical: .regular, hinge: .partiallyOpen, fold: fold) == .book)
    }

    @Test func partiallyOpenWithHorizontalCreaseIsTent() {
        let fold = CGRect(x: 0, y: 390, width: 900, height: 20)
        #expect(DuoPosture.resolve(horizontal: .regular, vertical: .regular, hinge: .partiallyOpen, fold: fold) == .tent)
    }

    @Test func partiallyOpenWithoutFoldFallsBackToSizeClass() {
        #expect(DuoPosture.resolve(horizontal: .regular, vertical: .regular, hinge: .partiallyOpen) == .expanded)
    }

    @Test func isOpenCoversEveryInnerDisplayPosture() {
        #expect(!DuoPosture.compact.isOpen)
        #expect(DuoPosture.expanded.isOpen)
        #expect(DuoPosture.book.isOpen)
        #expect(DuoPosture.tent.isOpen)
    }
}

@Suite struct GridTests {
    @Test func fitsAsManyColumnsAsMinimumWidthAllows() {
        #expect(DuoGridMetrics.columnCount(width: 390, minColumnWidth: 160, spacing: 12) == 2)
        #expect(DuoGridMetrics.columnCount(width: 1000, minColumnWidth: 160, spacing: 12) == 5)
    }

    @Test func neverFewerThanOneColumn() {
        #expect(DuoGridMetrics.columnCount(width: 100, minColumnWidth: 160, spacing: 12) == 1)
        #expect(DuoGridMetrics.columnCount(width: 0, minColumnWidth: 160, spacing: 12) == 1)
    }

    @Test func infiniteOrInvalidWidthsDoNotTrap() {
        // SwiftUI stacks probe children with an infinite proposal.
        #expect(DuoGridMetrics.columnCount(width: .infinity, minColumnWidth: 160, spacing: 12) == 1)
        #expect(DuoGridMetrics.columnCount(width: .infinity, minColumnWidth: 160, spacing: 12, maxColumns: 4) == 4)
        #expect(DuoGridMetrics.columnCount(width: .nan, minColumnWidth: 160, spacing: 12) == 1)
        #expect(DuoGridMetrics.columnCount(width: 400, minColumnWidth: 0, spacing: 0) == 1)
    }

    @Test func preferEvenRoundsOddCountsDown() {
        #expect(DuoGridMetrics.columnCount(width: 1000, minColumnWidth: 160, spacing: 12, preferEven: true) == 4)
        #expect(DuoGridMetrics.columnCount(width: 100, minColumnWidth: 160, spacing: 12, preferEven: true) == 1)
    }

    @Test func maxColumnsCaps() {
        #expect(DuoGridMetrics.columnCount(width: 1000, minColumnWidth: 160, spacing: 12, maxColumns: 3) == 3)
    }

    @Test func columnsWithoutFoldShareWidthEvenly() {
        let cols = DuoGridMetrics.columns(width: 412, minColumnWidth: 160, spacing: 12)
        #expect(cols == [DuoColumn(x: 0, width: 200), DuoColumn(x: 212, width: 200)])
    }

    @Test func withoutFoldOpenGridsAreEven() {
        let cols = DuoGridMetrics.columns(width: 1000, minColumnWidth: 160, spacing: 12, preferEven: true)
        #expect(cols.count == 4)
    }

    @Test func eachSideOfTheFoldGetsItsOwnColumns() {
        // Fold occupies 500...520. Each side lays out its own columns,
        // with half a gutter between the fold and the nearest column.
        let cols = DuoGridMetrics.columns(width: 1020, minColumnWidth: 400, spacing: 12, fold: 500...520)
        #expect(cols == [DuoColumn(x: 0, width: 494), DuoColumn(x: 526, width: 494)])
    }

    @Test func aSideTooNarrowForACardStaysEmpty() {
        // A grid beside a sidebar: the crease is only 100pt in.
        let cols = DuoGridMetrics.columns(width: 700, minColumnWidth: 160, spacing: 12, fold: 100...124)
        #expect(cols == [DuoColumn(x: 130, width: 182), DuoColumn(x: 324, width: 182), DuoColumn(x: 518, width: 182)])
    }

    @Test func foldOutsideTheGridIsIgnored() {
        let cols = DuoGridMetrics.columns(width: 412, minColumnWidth: 160, spacing: 12, fold: 500...520)
        #expect(cols == DuoGridMetrics.columns(width: 412, minColumnWidth: 160, spacing: 12))
    }

    @Test func maxColumnsHoldsAcrossTheFold() {
        let cols = DuoGridMetrics.columns(width: 1020, minColumnWidth: 100, spacing: 12, maxColumns: 2, fold: 500...520)
        #expect(cols.count == 2)
    }
}

@Suite struct FoldDisplacementTests {
    let verticalFold = CGRect(x: 500, y: 0, width: 20, height: 1000)

    @Test func clearOfFoldStaysPut() {
        let frame = CGRect(x: 100, y: 100, width: 100, height: 40)
        #expect(DuoFoldAvoidance.offset(for: frame, fold: verticalFold) == .zero)
    }

    @Test func movesToTheNearerSide() {
        let mostlyLeft = CGRect(x: 420, y: 100, width: 100, height: 40) // 420...520
        #expect(DuoFoldAvoidance.offset(for: mostlyLeft, fold: verticalFold) == CGSize(width: -20, height: 0))

        let mostlyRight = CGRect(x: 510, y: 100, width: 100, height: 40) // 510...610
        #expect(DuoFoldAvoidance.offset(for: mostlyRight, fold: verticalFold) == CGSize(width: 10, height: 0))
    }

    @Test func horizontalFoldMovesVertically() {
        let fold = CGRect(x: 0, y: 500, width: 1000, height: 20)
        let frame = CGRect(x: 100, y: 490, width: 100, height: 20) // 490...510
        #expect(DuoFoldAvoidance.offset(for: frame, fold: fold) == CGSize(width: 0, height: -10))
    }

    @Test func viewsWiderThanEitherSideAreLeftAlone() {
        let bounds = CGRect(x: 0, y: 0, width: 1020, height: 1000)
        let wide = CGRect(x: 0, y: 0, width: 900, height: 40)
        #expect(DuoFoldAvoidance.offset(for: wide, fold: verticalFold, in: bounds) == .zero)
    }
}

@Suite struct TabPlacementTests {
    @Test func regularWidthGetsSidebar() {
        #expect(DuoTabPlacement.resolve(horizontalRegular: true, verticalEdge: .trailing) == .sidebar)
    }

    @Test func sidebarCanBeDeclined() {
        #expect(DuoTabPlacement.resolve(horizontalRegular: true, verticalEdge: nil, allowsSidebar: false) == .bottomBar)
        #expect(DuoTabPlacement.resolve(horizontalRegular: true, verticalEdge: .trailing, allowsSidebar: false) == .rail(.trailing))
    }

    @Test func verticalBarsMakeARail() {
        #expect(DuoTabPlacement.resolve(horizontalRegular: false, verticalEdge: .trailing) == .rail(.trailing))
    }

    @Test func otherwiseBottomBar() {
        #expect(DuoTabPlacement.resolve(horizontalRegular: false, verticalEdge: nil) == .bottomBar)
    }
}
