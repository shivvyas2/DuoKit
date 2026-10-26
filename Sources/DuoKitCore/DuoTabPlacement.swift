/// Where a custom tab bar belongs.
public enum DuoTabPlacement: Sendable, Hashable {
    /// The familiar iPhone bar along the bottom.
    case bottomBar
    /// A vertical column of icons on the edge where the system puts its own
    /// bars: the outer display, and the inner display in landscape.
    case rail(DuoEdge)
    /// A list down the leading side of the inner display.
    case sidebar

    public var isVertical: Bool { self != .bottomBar }

    public static func resolve(
        horizontalRegular: Bool,
        verticalEdge: DuoEdge?,
        allowsSidebar: Bool = true
    ) -> DuoTabPlacement {
        if horizontalRegular, allowsSidebar { return .sidebar }
        if let verticalEdge { return .rail(verticalEdge) }
        return .bottomBar
    }
}
