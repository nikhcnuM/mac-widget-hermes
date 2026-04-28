import SwiftUI

struct ContentView: View {
    @StateObject private var model = HermesCompanionModel()

    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Hermes Companion")
                    .font(.largeTitle.weight(.bold))

                Text(model.connectionStatus)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(model.connectionStatus == "Connected" ? .green : .secondary)

                Divider()

                Text("Transcript")
                    .font(.headline)
                Text(model.content.transcript)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.secondary)

                Text("Hermes")
                    .font(.headline)
                Text(model.content.assistantText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                HStack {
                    Button("Connect") { model.connect() }
                    Button("Disconnect") { model.disconnect() }
                }
            }
            .frame(minWidth: 360, maxWidth: .infinity, alignment: .topLeading)
            .padding(24)

            WidgetCardView(content: model.content, layout: .preview)
                .frame(width: 360, height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(24)
        }
        .frame(minWidth: 820, minHeight: 420)
        .task {
            model.connect()
        }
    }
}
