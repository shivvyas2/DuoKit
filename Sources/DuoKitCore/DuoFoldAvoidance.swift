import CoreGraphics

/// Displacement: move an element just far enough that it no longer sits in
/// the fold, toward whichever side is nearer. HIG asks for minimal movement
/// and no redesign.
public enum DuoFoldAvoidance {
    /// The offset that clears `frame` from `fold`. Zero when it is already
    /// clear, or when it cannot fit on either side within `bounds`.
    public static func offset(for frame: CGRect, fold: CGRect, in bounds: CGRect? = nil) -> CGSize {
        guard frame.intersects(fold) else { return .zero }
        let verticalCrease = fold.height >= fold.width

        let toStart = verticalCrease ? fold.minX - frame.maxX : fold.minY - frame.maxY
        let toEnd = verticalCrease ? fold.maxX - frame.minX : fold.maxY - frame.minY

        let candidates = [toStart, toEnd]
            .filter { fits(frame, moved: $0, vertically: !verticalCrease, in: bounds) }
            .sorted { abs($0) < abs($1) }
        guard let move = candidates.first else { return .zero }
        return verticalCrease ? CGSize(width: move, height: 0) : CGSize(width: 0, height: move)
    }

    private static func fits(_ frame: CGRect, moved distance: CGFloat, vertically: Bool, in bounds: CGRect?) -> Bool {
        guard let bounds else { return true }
        let moved = frame.offsetBy(dx: vertically ? 0 : distance, dy: vertically ? distance : 0)
        return bounds.contains(moved)
    }
}
