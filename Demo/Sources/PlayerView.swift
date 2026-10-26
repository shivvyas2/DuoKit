import DuoKit
import SwiftUI

/// Tent posture: artwork up top where it can be seen across a table,
/// controls on the bottom half where a thumb reaches them.
struct PlayerView: View {
    @State private var playing = true
    @State private var progress = 0.34

    var body: some View {
        DuoTentLayout {
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(colors: [Palette.violet, Palette.ember], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(Image(systemName: "music.note").font(.system(size: 64, weight: .bold)).foregroundStyle(.white.opacity(0.8)))
                .aspectRatio(1, contentMode: .fit)
                .padding(24)
        } bottom: {
            VStack(spacing: 18) {
                VStack(spacing: 4) {
                    Text("Midnight Transit").font(.title2.bold())
                    Text("The Fold Lines").foregroundStyle(.secondary)
                }
                Slider(value: $progress)
                    .tint(Palette.lime)
                    .padding(.horizontal, 32)
                HStack(spacing: 44) {
                    Image(systemName: "backward.fill")
                    Button {
                        playing.toggle()
                    } label: {
                        Image(systemName: playing ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(Palette.lime)
                    }
                    Image(systemName: "forward.fill")
                }
                .font(.title)
            }
            .padding(.bottom, 16)
        }
    }
}
