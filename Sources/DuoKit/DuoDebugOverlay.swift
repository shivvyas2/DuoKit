#if os(iOS)
import DuoKitCore
import SwiftUI

public extension View {
    /// Draws what DuoKit sees while you develop: the safe area (blue), the
    /// crease (red), the inner camera (orange), and the current posture.
    /// Apply inside `.duoReady()`.
    func duoDebugOverlay(_ enabled: Bool = true) -> some View {
        overlay {
            if enabled { DuoDebugOverlay() }
        }
    }
}

private struct DuoDebugOverlay: View {
    @Environment(\.duoLayout) private var layout
    @Environment(\.duoSimulatedFold) private var simulatedFold

    var body: some View {
        // The outer reader stays inside the safe area so it can report the
        // insets; the inner one ignores it so drawing covers the whole screen.
        GeometryReader { safe in
            canvas(insets: safe.safeAreaInsets)
        }
        .allowsHitTesting(false)
    }

    private func canvas(insets: EdgeInsets) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .strokeBorder(.blue.opacity(0.8), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                    .padding(insets)

                if let fold = DuoProbe.fold(in: proxy, simulated: simulatedFold) {
                    region(fold, color: .red)
                }
                if let camera = DuoProbe.camera(in: proxy) {
                    region(camera, color: .orange)
                }

                DuoBarEdgeReader { edge in
                    Text(caption(edge: edge))
                        .font(.caption2.monospaced())
                        .padding(6)
                        .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 6))
                        .foregroundStyle(.white)
                }
                .padding(.leading, insets.leading + 8)
                .padding(.top, insets.top + 8)
            }
        }
        .ignoresSafeArea()
    }

    private func region(_ frame: CGRect, color: Color) -> some View {
        Rectangle()
            .fill(color.opacity(0.25))
            .overlay(Rectangle().strokeBorder(color, lineWidth: 1))
            .frame(width: max(frame.width, 2), height: max(frame.height, 2))
            .offset(x: frame.minX, y: frame.minY)
    }

    private func caption(edge: DuoEdge?) -> String {
        var parts = ["\(layout.posture)"]
        parts.append(edge.map { "bars: \($0)" } ?? "bars: bottom")
        if let angle = layout.hingeAngle { parts.append("hinge: \(Int(angle))°") }
        return parts.joined(separator: " · ")
    }
}
#endif
