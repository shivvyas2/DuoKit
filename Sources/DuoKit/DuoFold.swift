#if os(iOS)
import DuoKitCore
import SwiftUI

public extension View {
    /// Nudges this view just clear of the crease when the Duo is partially
    /// folded, toward the nearer side. For buttons, cards and alerts, not for
    /// scrolling content, which HIG lets run across the fold.
    func avoidsFold() -> some View {
        modifier(AvoidsFold())
    }
}

private struct AvoidsFold: ViewModifier {
    @Environment(\.duoSimulatedFold) private var simulatedFold
    @State private var offset: CGSize = .zero

    func body(content: Content) -> some View {
        let simulatedFold = simulatedFold
        content
            .onGeometryChange(for: CGSize.self) { proxy in
                guard let fold = DuoProbe.fold(in: proxy, simulated: simulatedFold) else { return .zero }
                return DuoFoldAvoidance.offset(for: CGRect(origin: .zero, size: proxy.size), fold: fold)
            } action: {
                offset = $0
            }
            .offset(offset)
            .animation(.snappy, value: offset)
    }
}

/// For the tent posture: glanceable content above the crease, controls below.
/// When the Duo is not in tent, the two halves simply stack.
///
///     DuoTentLayout {
///         NowPlayingArtwork()
///     } bottom: {
///         PlaybackControls()
///     }
public struct DuoTentLayout<Top: View, Bottom: View>: View {
    private let top: Top
    private let bottom: Bottom

    @Environment(\.duoLayout) private var layout
    @Environment(\.duoSimulatedFold) private var simulatedFold

    public init(@ViewBuilder top: () -> Top, @ViewBuilder bottom: () -> Bottom) {
        self.top = top()
        self.bottom = bottom()
    }

    public var body: some View {
        GeometryReader { proxy in
            let crease = layout.posture == .tent ? DuoProbe.fold(in: proxy, simulated: simulatedFold) : nil
            VStack(spacing: 0) {
                top
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(height: crease.map { max($0.minY, 0) })
                if let crease {
                    Color.clear.frame(height: crease.height)
                }
                bottom
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
#endif
