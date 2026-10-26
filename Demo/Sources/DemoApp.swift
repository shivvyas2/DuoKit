import DuoKit
import SwiftUI

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            DemoRoot()
        }
    }
}

/// The posture the demo pretends to be in. `Real` uses the device.
/// Launch with `-duoSimulate book` (closed, open, book, tent) to start in one.
enum SimulatedPosture: String, CaseIterable, Identifiable {
    case real, closed, open, book, tent

    var id: String { rawValue }

    var simulation: DuoSimulation? {
        switch self {
        case .real: nil
        case .closed: .closed
        case .open: .open
        case .book: .book
        case .tent: .tent
        }
    }
}

struct DemoRoot: View {
    @State private var posture = SimulatedPosture(rawValue: UserDefaults.standard.string(forKey: "duoSimulate") ?? "") ?? .real
    @State private var showsOverlay = UserDefaults.standard.bool(forKey: "duoOverlay")

    var body: some View {
        DemoShell(posture: $posture, showsOverlay: $showsOverlay)
            .duoDebugOverlay(showsOverlay)
            .duoReady()
            .duoSimulate(posture.simulation)
            .preferredColorScheme(.dark)
    }
}

enum DemoTab: String, CaseIterable, Hashable {
    case today, inbox, player, lab

    var title: String {
        switch self {
        case .today: "Today"
        case .inbox: "Inbox"
        case .player: "Player"
        case .lab: "Lab"
        }
    }

    var symbol: String {
        switch self {
        case .today: "heart.text.square.fill"
        case .inbox: "tray.fill"
        case .player: "play.circle.fill"
        case .lab: "slider.horizontal.3"
        }
    }
}

struct DemoShell: View {
    @Binding var posture: SimulatedPosture
    @Binding var showsOverlay: Bool
    @State private var tab = DemoTab(rawValue: UserDefaults.standard.string(forKey: "duoTab") ?? "") ?? .today

    var body: some View {
        DuoTabShell(selection: $tab, tabs: DemoTab.allCases) { tab in
            switch tab {
            case .today: TodayView()
            case .inbox: InboxView()
            case .player: PlayerView()
            case .lab: LabView(posture: $posture, showsOverlay: $showsOverlay)
            }
        } item: { tab, context in
            DuoTabLabel(tab.title, systemImage: tab.symbol, context: context, tint: Palette.lime)
        }
        .background(Palette.background.ignoresSafeArea())
    }
}

enum Palette {
    static let background = Color(red: 0.04, green: 0.04, blue: 0.05)
    static let card = Color(red: 0.09, green: 0.09, blue: 0.11)
    static let lime = Color(red: 0.87, green: 0.93, blue: 0.42)
    static let ember = Color(red: 1, green: 0.42, blue: 0.24)
    static let violet = Color(red: 0.49, green: 0.42, blue: 1)
}
