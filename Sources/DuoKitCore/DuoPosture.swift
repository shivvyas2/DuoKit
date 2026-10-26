import CoreGraphics

/// A size class without SwiftUI, so the decisions below are testable anywhere.
public enum DuoSizeClass: Sendable {
    case compact, regular
}

/// Mirrors `DeviceHinge.Status` from iOS 27.1.
public enum DuoHingeStatus: Sendable {
    case closed, partiallyOpen, fullyOpen
}

/// A horizontal edge of the screen, for bars that stand vertically.
public enum DuoEdge: Sendable, Hashable {
    case leading, trailing
}

/// How the device is being held, as far as layout cares.
///
/// Apple's guidance is to lay out by size class, not by pose. The partially
/// folded postures exist only for the few layouts that should react to the
/// crease: displacement away from it, and tent's top/bottom split.
public enum DuoPosture: Sendable, Hashable {
    /// Outer display, or any compact-width window.
    case compact
    /// Inner display, flat.
    case expanded
    /// Inner display, partially folded along a vertical crease, held like a book.
    case book
    /// Inner display, partially folded along a horizontal crease, propped up like a tent.
    case tent

    /// True on the inner display in any posture.
    public var isOpen: Bool { self != .compact }

    public static func resolve(
        horizontal: DuoSizeClass,
        vertical: DuoSizeClass,
        hinge: DuoHingeStatus? = nil,
        fold: CGRect? = nil
    ) -> DuoPosture {
        guard horizontal == .regular else { return .compact }
        if hinge == .partiallyOpen, let fold {
            return fold.width > fold.height ? .tent : .book
        }
        return vertical == .regular ? .expanded : .compact
    }
}
