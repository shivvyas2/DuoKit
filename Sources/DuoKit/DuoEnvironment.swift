#if os(iOS)
import DuoKitCore
import SwiftUI

/// What DuoKit knows about the device, published by `.duoReady()`.
public struct DuoLayout: Equatable, Sendable {
    public var posture: DuoPosture
    /// Nil on devices without a hinge, and on iOS before 27.1.
    public var hinge: DuoHingeStatus?
    /// Degrees between the halves; 180 is flat. For effects, not layout.
    public var hingeAngle: Double?

    public init(posture: DuoPosture = .compact, hinge: DuoHingeStatus? = nil, hingeAngle: Double? = nil) {
        self.posture = posture
        self.hinge = hinge
        self.hingeAngle = hingeAngle
    }

    /// True when running on hardware that reports a hinge.
    public var isFoldable: Bool { hinge != nil }
}

/// Forces a posture so every DuoKit component can be seen on an ordinary
/// simulator or in a preview. Real devices ignore it unless it is set.
public struct DuoSimulation: Equatable, Sendable {
    public var posture: DuoPosture
    public var barEdge: DuoEdge?

    public init(posture: DuoPosture, barEdge: DuoEdge? = nil) {
        self.posture = posture
        self.barEdge = barEdge
    }

    /// Outer display: bars stand on the right.
    public static let closed = DuoSimulation(posture: .compact, barEdge: .trailing)
    /// Inner display, flat.
    public static let open = DuoSimulation(posture: .expanded)
    /// Inner display partially folded along a vertical crease.
    public static let book = DuoSimulation(posture: .book)
    /// Inner display partially folded along a horizontal crease.
    public static let tent = DuoSimulation(posture: .tent)

    /// The simulated crease, in a window of `size`.
    func fold(in size: CGSize) -> CGRect? {
        let band: CGFloat = 24
        switch posture {
        case .book: return CGRect(x: size.width / 2 - band / 2, y: 0, width: band, height: size.height)
        case .tent: return CGRect(x: 0, y: size.height / 2 - band / 2, width: size.width, height: band)
        case .compact, .expanded: return nil
        }
    }
}

extension EnvironmentValues {
    @Entry public var duoLayout = DuoLayout()
    @Entry var duoSimulation: DuoSimulation? = nil
    /// The simulated crease in global coordinates, set by `.duoReady()`.
    @Entry var duoSimulatedFold: CGRect? = nil
    /// Where DuoKit expects vertical bars when the system does not say:
    /// the trailing edge on the outer display and in inner landscape.
    @Entry var duoInferredBarEdge: DuoEdge? = nil
}

public extension View {
    /// Pretend to be an iPhone Duo in `simulation`'s posture. Pass nil to use
    /// the real device. Apply outside `.duoReady()`.
    func duoSimulate(_ simulation: DuoSimulation?) -> some View {
        environment(\.duoSimulation, simulation)
    }
}

extension UserInterfaceSizeClass? {
    var duo: DuoSizeClass { self == .regular ? .regular : .compact }
}

/// Reads iOS 27.1 reserved regions, or the simulated crease, in a view's own
/// coordinate space.
enum DuoProbe {
    static func fold(in proxy: GeometryProxy, simulated: CGRect?) -> CGRect? {
        if let simulated {
            let origin = proxy.frame(in: .global).origin
            return simulated.offsetBy(dx: -origin.x, dy: -origin.y)
        }
        if #available(iOS 27.1, *) {
            return proxy.reservedRegions(kind: .division).first(where: \.isActive)?.frame
        }
        return nil
    }

    /// The camera cutout on the inner display, active or not.
    static func camera(in proxy: GeometryProxy) -> CGRect? {
        if #available(iOS 27.1, *) {
            return proxy.reservedRegions(kind: .occlusion, options: .includeInactive).first?.frame
        }
        return nil
    }
}

/// Hands its content the edge vertical bars belong on, or nil when bars run
/// horizontally. Prefers the system's answer (`toolbarVerticalEdge`, iOS 27.1).
public struct DuoBarEdgeReader<Content: View>: View {
    @Environment(\.duoSimulation) private var simulation
    @Environment(\.duoInferredBarEdge) private var inferred
    private let content: (DuoEdge?) -> Content

    public init(@ViewBuilder content: @escaping (DuoEdge?) -> Content) {
        self.content = content
    }

    public var body: some View {
        if let simulation {
            content(simulation.barEdge)
        } else if #available(iOS 27.1, *) {
            SystemBarEdge(fallback: inferred, content: content)
        } else {
            content(nil)
        }
    }
}

@available(iOS 27.1, *)
private struct SystemBarEdge<Content: View>: View {
    @Environment(\.toolbarVerticalEdge) private var edge
    let fallback: DuoEdge?
    let content: (DuoEdge?) -> Content

    var body: some View {
        content(edge.map { $0 == .leading ? .leading : .trailing } ?? fallback)
    }
}
#endif
