#if os(iOS)
import DuoKitCore
import SwiftUI

/// A container for a custom bar of icon buttons. Lays its items in a row, or
/// in a column whenever the system stands its own bars vertically.
///
/// HIG: icon-only controls can go vertical; text-only controls, segmented
/// controls and toggles that swap icon for label should stay horizontal, so
/// keep those out of a `DuoBar`. Order items top to bottom the way they read
/// left to right: Back or Close first, then the prominent action.
public struct DuoBar<Content: View>: View {
    private let spacing: CGFloat?
    private let content: Content

    public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        DuoBarEdgeReader { edge in
            let layout = edge == nil
                ? AnyLayout(HStackLayout(spacing: spacing))
                : AnyLayout(VStackLayout(spacing: spacing))
            layout { content }
                .environment(\.duoBarIsVertical, edge != nil)
        }
    }
}

public extension View {
    /// Pins a `DuoBar` (or any bar) to the bottom normally, and to the edge the
    /// system uses for vertical bars when they stand up. Content is inset
    /// either way, so nothing scrolls under it unreachable.
    func duoBarInset<Bar: View>(@ViewBuilder _ bar: @escaping () -> Bar) -> some View {
        DuoBarEdgeReader { edge in
            self
                .safeAreaInset(edge: .bottom, spacing: 0) { if edge == nil { bar() } }
                .safeAreaInset(edge: .leading, spacing: 0) { if edge == .leading { bar() } }
                .safeAreaInset(edge: .trailing, spacing: 0) { if edge == .trailing { bar() } }
        }
    }
}

extension EnvironmentValues {
    /// True inside a `DuoBar` that is laid out as a column.
    @Entry public var duoBarIsVertical = false
}
#endif
