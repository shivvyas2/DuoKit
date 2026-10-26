import DuoKit
import SwiftUI

/// Switch postures on any simulator, and show what DuoKit currently sees.
struct LabView: View {
    @Binding var posture: SimulatedPosture
    @Binding var showsOverlay: Bool
    @Environment(\.duoLayout) private var layout

    var body: some View {
        Form {
            Section {
                Picker("Posture", selection: $posture) {
                    ForEach(SimulatedPosture.allCases) { Text($0.rawValue.capitalized).tag($0) }
                }
                .pickerStyle(.segmented)
                Toggle("Debug overlay", isOn: $showsOverlay)
            } header: {
                Text("Simulate")
            } footer: {
                Text("Real uses the device. On the iPhone Duo simulator, fold and rotate it from Device Hub instead.")
            }

            Section("DuoKit sees") {
                LabeledContent("Posture", value: "\(layout.posture)")
                LabeledContent("Hinge", value: layout.hinge.map { "\($0)" } ?? "none")
                LabeledContent("Hinge angle", value: layout.hingeAngle.map { "\(Int($0))°" } ?? "none")
                DuoBarEdgeReader { edge in
                    LabeledContent("Vertical bars", value: edge.map { "\($0)" } ?? "no")
                }
            }

            Section("Custom bar") {
                DuoBar(spacing: 16) {
                    Image(systemName: "xmark")
                    Image(systemName: "checkmark")
                    Image(systemName: "square.and.arrow.up")
                    Image(systemName: "trash")
                }
                .font(.title3)
                .frame(maxWidth: .infinity)
            }
        }
        .scrollContentBackground(.hidden)
    }
}
