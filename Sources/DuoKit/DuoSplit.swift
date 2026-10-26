#if os(iOS)
import DuoKitCore
import SwiftUI

/// Two views that belong together, like a list and its detail, a chart and
/// its legend, or a map and its results. Neither ever covers the other.
///
/// On iOS 27.1 this is Apple's `ArrangementView` with the split style, which
/// places the pair side by side or stacked and keeps the fold between them.
/// Earlier, it is side by side when open and stacked when folded.
public struct DuoSplit<Primary: View, Secondary: View>: View {
    private let primary: Primary
    private let secondary: Secondary

    @Environment(\.duoLayout) private var layout
    @Environment(\.duoSimulation) private var simulation

    public init(@ViewBuilder primary: () -> Primary, @ViewBuilder secondary: () -> Secondary) {
        self.primary = primary()
        self.secondary = secondary()
    }

    public var body: some View {
        if simulation == nil, #available(iOS 27.1, *) {
            ArrangementView {
                primary
            } secondary: {
                secondary
            }
            .arrangementViewStyle(.split)
        } else {
            fallback
        }
    }

    private var fallback: some View {
        let open = layout.posture.isOpen
        let stack = open ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
        return stack {
            primary.frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            secondary.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
#endif
