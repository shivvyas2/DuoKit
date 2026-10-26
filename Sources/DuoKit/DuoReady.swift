#if os(iOS)
import DuoKitCore
import SwiftUI

public extension View {
    /// Apply once, at the root of each scene. Publishes `duoLayout` to every
    /// DuoKit component below and, on the inner display, opts system tab views
    /// into a sidebar (`sidebar: false` keeps the tab bar).
    ///
    /// Safe everywhere: on iOS before 27.1 and on phones without a hinge it
    /// only reports size classes.
    func duoReady(sidebar: Bool = true) -> some View {
        modifier(DuoReadyModifier(sidebar: sidebar))
    }
}

struct DuoReadyModifier: ViewModifier {
    let sidebar: Bool

    @Environment(\.horizontalSizeClass) private var horizontal
    @Environment(\.verticalSizeClass) private var vertical
    @Environment(\.duoSimulation) private var simulation

    @State private var hinge: DuoHingeStatus?
    @State private var hingeAngle: Double?
    @State private var fold: CGRect?
    @State private var window: CGRect = .zero

    func body(content: Content) -> some View {
        content
            .environment(\.duoLayout, layout)
            .environment(\.duoSimulatedFold, simulatedFold)
            .environment(\.duoInferredBarEdge, inferredBarEdge)
            .modifier(SidebarPlacement(enabled: sidebar && layout.posture.isOpen))
            .modifier(HingeObserver(hinge: $hinge, angle: $hingeAngle))
            .onGeometryChange(for: CGRect?.self) { DuoProbe.fold(in: $0, simulated: nil) } action: { fold = $0 }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { window = $0 }
    }

    private var layout: DuoLayout {
        if let simulation {
            let folded = simulation.posture == .book || simulation.posture == .tent
            return DuoLayout(posture: simulation.posture, hinge: folded ? .partiallyOpen : .fullyOpen)
        }
        return DuoLayout(
            posture: .resolve(horizontal: horizontal.duo, vertical: vertical.duo, hinge: hinge, fold: fold),
            hinge: hinge,
            hingeAngle: hingeAngle
        )
    }

    private var simulatedFold: CGRect? {
        simulation?.fold(in: window.size)?.offsetBy(dx: window.minX, dy: window.minY)
    }

    /// HIG: on the outer display, and on the inner display in landscape,
    /// bars stand on the right edge.
    private var inferredBarEdge: DuoEdge? {
        guard layout.isFoldable else { return nil }
        if !layout.posture.isOpen || window.width > window.height { return .trailing }
        return nil
    }
}

private struct SidebarPlacement: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if #available(iOS 27.0, *) {
            content.defaultTabBarPlacement(enabled ? .sidebar : .automatic)
        } else {
            content
        }
    }
}

private struct HingeObserver: ViewModifier {
    @Binding var hinge: DuoHingeStatus?
    @Binding var angle: Double?

    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            content.onHingeChange { _, context in
                hinge = context.hinge.map { DuoHingeStatus($0.status) }
                angle = context.hinge?.angle.degrees
            }
        } else {
            content
        }
    }
}

@available(iOS 27.1, *)
extension DuoHingeStatus {
    init(_ status: DeviceHinge.Status) {
        if status == .closed {
            self = .closed
        } else if status == .partiallyOpen {
            self = .partiallyOpen
        } else {
            self = .fullyOpen
        }
    }
}
#endif
