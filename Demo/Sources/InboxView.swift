import DuoKit
import SwiftUI

/// List and detail in a DuoSplit: stacked when folded, side by side when open,
/// with the crease between them when held like a book.
struct InboxView: View {
    @State private var selected = Message.samples[0]

    var body: some View {
        DuoSplit {
            List(Message.samples, selection: Binding(get: { selected.id }, set: { id in
                if let message = Message.samples.first(where: { $0.id == id }) { selected = message }
            })) { message in
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.sender).font(.headline)
                    Text(message.subject).font(.subheadline)
                    Text(message.body).font(.footnote).foregroundStyle(.secondary).lineLimit(1)
                }
                .padding(.vertical, 4)
                .tag(message.id)
            }
            .scrollContentBackground(.hidden)
        } secondary: {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(selected.subject).font(.title2.bold())
                    Text("From \(selected.sender)").foregroundStyle(.secondary)
                    Text(selected.body)
                    HStack {
                        Button("Reply", systemImage: "arrowshape.turn.up.left") {}
                        Button("Archive", systemImage: "archivebox") {}
                    }
                    .buttonStyle(.bordered)
                    .avoidsFold()
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct Message: Identifiable, Hashable {
    let id: Int
    let sender: String
    let subject: String
    let body: String

    static let samples: [Message] = [
        Message(id: 1, sender: "Maya", subject: "Trip photos", body: "Uploaded the whole album. The sunset ones from the ridge came out unreal."),
        Message(id: 2, sender: "Design team", subject: "Duo review on Thursday", body: "Bring the folded and open screenshots for every screen you own."),
        Message(id: 3, sender: "Coach", subject: "This week's plan", body: "Two strength sessions, one long run, and actually sleep eight hours."),
        Message(id: 4, sender: "Bank", subject: "Statement ready", body: "Your October statement is available in the app."),
    ]
}
