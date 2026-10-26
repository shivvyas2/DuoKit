import DuoKit
import SwiftUI

/// A health dashboard like the one that looks stretched on iPhone Duo today,
/// rebuilt on DuoGrid: rings span the row, cards reflow into columns.
struct TodayView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Today")
                    .font(.largeTitle.bold())

                DuoGrid(minColumnWidth: 170, spacing: 12) {
                    RingsCard()
                        .duoGridSpan(.full)
                    MetricCard(title: "Health monitor", value: "5/5", detail: "Within range", tint: Palette.lime, symbol: "checkmark.seal.fill")
                    MetricCard(title: "Stress", value: "1.1", detail: "Medium · 5:02 PM", tint: Palette.ember, symbol: "waveform.path.ecg")
                    MetricCard(title: "Resting HR", value: "54", detail: "bpm · −3 this week", tint: Palette.violet, symbol: "heart.fill")
                    MetricCard(title: "HRV", value: "71", detail: "ms · above baseline", tint: Palette.lime, symbol: "bolt.heart.fill")
                    MetricCard(title: "Steps", value: "8,412", detail: "84% of goal", tint: Palette.ember, symbol: "figure.walk")
                    MetricCard(title: "Respiratory", value: "14.2", detail: "rpm · normal", tint: Palette.violet, symbol: "lungs.fill")
                    ActivitiesCard()
                        .duoGridSpan(.full)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

private struct RingsCard: View {
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 32) { rings(size: 96) }
                .frame(maxWidth: .infinity)
            HStack(spacing: 12) { rings(size: 96) }
            HStack(spacing: 10) { rings(size: 72) }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 22))
    }

    @ViewBuilder private func rings(size: CGFloat) -> some View {
        Ring(label: "Sleep", value: 0.67, text: "67%", tint: .white, size: size)
        Ring(label: "Recovery", value: 0.5, text: "50%", tint: .yellow, size: size)
        Ring(label: "Strain", value: 0.21, text: "2.1", tint: .cyan, size: size)
    }
}

private struct Ring: View {
    let label: String
    let value: Double
    let text: String
    let tint: Color
    let size: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().stroke(.white.opacity(0.12), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: value)
                    .stroke(tint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(text).font((size < 90 ? Font.headline : .title2).bold().monospacedDigit())
            }
            .frame(width: size, height: size)
            Text(label.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let detail: String
    let tint: Color
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title.uppercased(), systemImage: symbol)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 22))
    }
}

private struct ActivitiesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TODAY'S ACTIVITIES")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            ForEach(["Morning run · 5.2 km", "Strength · 42 min", "Evening walk · 2.1 km"], id: \.self) { item in
                HStack {
                    Text(item)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                }
                .padding(.vertical, 6)
            }
        }
        .padding(16)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 22))
    }
}
