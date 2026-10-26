#if os(iOS)
import DuoKitCore
import SwiftUI

/// What a tab item needs to draw itself.
public struct DuoTabItemContext: Sendable {
    public var isSelected: Bool
    public var placement: DuoTabPlacement
}

/// The tab items, already stacked for the current placement. Wrap it in your
/// bar's own chrome (capsule, material, border) in `DuoTabShell`'s `chrome`.
public struct DuoTabItems: View {
    let content: AnyView
    public var body: some View { content }
}

/// For apps with a hand-built tab bar. Keeps the app's look, and moves the bar
/// where the Duo expects it:
///
/// - folded, bars horizontal: along the bottom, as on any iPhone
/// - folded, bars vertical: a rail on the system's bar edge
/// - open: a sidebar down the leading side
///
/// Tabs are created the first time they are shown and then kept, so scroll
/// positions and state survive both tab switches and folding.
public struct DuoTabShell<Tab: Hashable, Content: View, Item: View, Chrome: View>: View {
    @Binding private var selection: Tab
    private let tabs: [Tab]
    private let allowsSidebar: Bool
    private let bottomBarBehavior: DuoBottomBarBehavior
    private let content: (Tab) -> Content
    private let item: (Tab, DuoTabItemContext) -> Item
    private let chrome: (DuoTabPlacement, DuoTabItems) -> Chrome

    @Environment(\.duoLayout) private var layout
    @Environment(\.duoSimulatedFold) private var simulatedFold
    @State private var opened: Set<Tab> = []
    @State private var crease: CGRect?

    public init(
        selection: Binding<Tab>,
        tabs: [Tab],
        allowsSidebar: Bool = true,
        bottomBar: DuoBottomBarBehavior = .insetsContent,
        @ViewBuilder content: @escaping (Tab) -> Content,
        @ViewBuilder item: @escaping (Tab, DuoTabItemContext) -> Item,
        @ViewBuilder chrome: @escaping (DuoTabPlacement, DuoTabItems) -> Chrome
    ) {
        _selection = selection
        self.tabs = tabs
        self.allowsSidebar = allowsSidebar
        self.bottomBarBehavior = bottomBar
        self.content = content
        self.item = item
        self.chrome = chrome
    }

    public var body: some View {
        DuoBarEdgeReader { edge in
            let placement = DuoTabPlacement.resolve(
                horizontalRegular: layout.posture.isOpen,
                verticalEdge: edge,
                allowsSidebar: allowsSidebar
            )
            // Side placements are plain layout, which reaches inside every
            // page's navigation stack. The pages keep one structural position
            // in every placement, so folding never rebuilds them.
            HStack(spacing: 0) {
                if placement == .sidebar || placement == .rail(.leading) {
                    chrome(placement, items(placement))
                }
                bottomBarHost(placement)
                if placement == .rail(.trailing) {
                    chrome(placement, items(placement))
                }
            }
            .animation(.snappy, value: placement)
        }
        .environment(\.duoSidebarWidth, sidebarWidth)
        .onGeometryChange(for: CGRect?.self) { [simulatedFold] proxy in
            DuoProbe.fold(in: proxy, simulated: simulatedFold)
        } action: {
            crease = $0
        }
        .onAppear { opened.insert(selection) }
        .onChange(of: selection) { _, tab in opened.insert(tab) }
    }

    /// Held like a book, the sidebar takes the whole left page, crease
    /// included, so navigation and content each get a page of their own.
    private var sidebarWidth: CGFloat {
        guard layout.posture == .book, let crease, crease.minX >= DuoMetrics.sidebarWidth * 0.75 else {
            return DuoMetrics.sidebarWidth
        }
        return crease.maxX
    }

    @ViewBuilder
    private func bottomBarHost(_ placement: DuoTabPlacement) -> some View {
        let bar = placement == .bottomBar
        switch bottomBarBehavior {
        case .insetsContent:
            pages
                .environment(\.duoTabPlacement, placement)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if bar { chrome(placement, items(placement)) }
                }
        case .overlaysContent:
            pages
                .environment(\.duoTabPlacement, placement)
                .overlay(alignment: .bottom) {
                    if bar { chrome(placement, items(placement)) }
                }
        }
    }

    private var pages: some View {
        ZStack {
            ForEach(tabs, id: \.self) { tab in
                if opened.contains(tab) {
                    let selected = tab == selection
                    content(tab)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .opacity(selected ? 1 : 0)
                        .allowsHitTesting(selected)
                        .accessibilityHidden(!selected)
                }
            }
        }
    }

    private func items(_ placement: DuoTabPlacement) -> DuoTabItems {
        let stack = placement.isVertical
            ? AnyLayout(VStackLayout(alignment: placement == .sidebar ? .leading : .center, spacing: 2))
            : AnyLayout(HStackLayout(spacing: 2))
        return DuoTabItems(content: AnyView(
            stack {
                ForEach(tabs, id: \.self) { tab in
                    let context = DuoTabItemContext(isSelected: tab == selection, placement: placement)
                    Button {
                        selection = tab
                    } label: {
                        item(tab, context)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(context.isSelected ? .isSelected : [])
                }
            }
        ))
    }
}

/// How the bottom bar makes room for itself.
public enum DuoBottomBarBehavior: Sendable {
    /// The pages are inset by the bar's height. Right for most apps.
    case insetsContent
    /// The bar floats over the pages, which make their own room. For apps that
    /// already pad each page for their bar; read `duoTabPlacement` to pad only
    /// while the bar is at the bottom.
    case overlaysContent
}

extension EnvironmentValues {
    /// Where the enclosing `DuoTabShell` has put its bar.
    @Entry public var duoTabPlacement = DuoTabPlacement.bottomBar
}

public extension DuoTabShell where Chrome == DuoDefaultTabChrome {
    /// A shell with system-material chrome.
    init(
        selection: Binding<Tab>,
        tabs: [Tab],
        allowsSidebar: Bool = true,
        bottomBar: DuoBottomBarBehavior = .insetsContent,
        @ViewBuilder content: @escaping (Tab) -> Content,
        @ViewBuilder item: @escaping (Tab, DuoTabItemContext) -> Item
    ) {
        self.init(
            selection: selection,
            tabs: tabs,
            allowsSidebar: allowsSidebar,
            bottomBar: bottomBar,
            content: content,
            item: item
        ) {
            DuoDefaultTabChrome(placement: $0, items: $1)
        }
    }
}

/// Material capsule for bar and rail; a full-height material column for the sidebar.
public struct DuoDefaultTabChrome: View {
    let placement: DuoTabPlacement
    let items: DuoTabItems
    @Environment(\.duoSidebarWidth) private var sidebarWidth

    public var body: some View {
        switch placement {
        case .sidebar:
            items
                .padding(12)
                // Rows keep their usual width; a wider page-filling sidebar
                // just leaves room, so nothing reaches into the crease.
                .frame(width: min(sidebarWidth, DuoMetrics.sidebarWidth), alignment: .topLeading)
                .frame(width: sidebarWidth, alignment: .topLeading)
                .frame(maxHeight: .infinity, alignment: .top)
                .background(.bar)
        case .rail:
            items
                .padding(6)
                .background(.bar, in: Capsule())
                .padding(8)
                .frame(maxHeight: .infinity)
        case .bottomBar:
            items
                .padding(6)
                .background(.bar, in: Capsule())
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
        }
    }
}

/// A standard tab item: icon over a short title in the bar, icon alone in
/// the rail, icon beside the title in the sidebar.
public struct DuoTabLabel: View {
    private let title: String
    private let systemImage: String
    private let context: DuoTabItemContext
    private let tint: Color

    public init(_ title: String, systemImage: String, context: DuoTabItemContext, tint: Color = .accentColor) {
        self.title = title
        self.systemImage = systemImage
        self.context = context
        self.tint = tint
    }

    public var body: some View {
        Group {
            switch context.placement {
            case .bottomBar:
                VStack(spacing: 3) {
                    Image(systemName: systemImage).font(.system(size: 17, weight: .semibold))
                    Text(title).font(.caption2.weight(.semibold)).lineLimit(1)
                }
                .frame(maxWidth: .infinity, minHeight: 48)
            case .rail:
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 48, height: 48)
                    .accessibilityLabel(title)
            case .sidebar:
                Label(title, systemImage: systemImage)
                    .font(.body.weight(context.isSelected ? .semibold : .regular))
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(.horizontal, 12)
            }
        }
        .foregroundStyle(context.isSelected ? tint : .secondary)
        .background {
            if context.isSelected {
                Capsule().fill(tint.opacity(0.15))
            }
        }
        .contentShape(Capsule())
    }
}

public enum DuoMetrics {
    /// Matches the width of a system sidebar on the inner display.
    public static let sidebarWidth: CGFloat = 260
}

extension EnvironmentValues {
    /// The width a `DuoTabShell` sidebar should take right now. Custom chrome
    /// should use it so the sidebar fills the left page when held like a book.
    @Entry public var duoSidebarWidth = DuoMetrics.sidebarWidth
}
#endif
