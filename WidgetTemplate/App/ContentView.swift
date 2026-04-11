import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var title = WidgetContent.sample.title
    @State private var message = WidgetContent.sample.message
    @State private var accent = WidgetContent.sample.accent
    @State private var statusText = "Save to push the latest content into the widget."
    @State private var savedAt = WidgetContent.sample.updatedAt

    private let store = WidgetContentStore()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header

            HStack(alignment: .top, spacing: 24) {
                editorPanel
                previewPanel
            }
        }
        .padding(24)
        .task {
            loadStoredContent()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mac Widget Boilerplate")
                .font(.largeTitle.weight(.bold))

            Text("A tiny macOS app that edits the payload shown by the widget. Use it as the starting point for your own personal widgets.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var editorPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Editor")
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.headline)

                TextField("Widget title", text: $title)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Message")
                    .font(.headline)

                TextEditor(text: $message)
                    .font(.body)
                    .frame(minHeight: 140)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.primary.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Accent")
                    .font(.headline)

                Picker("Accent", selection: $accent) {
                    ForEach(WidgetAccent.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
            }

            HStack {
                Button("Load sample") {
                    applySample()
                }

                Button("Reload saved") {
                    loadStoredContent()
                }

                Spacer()

                Button("Save and reload widget") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
            }

            Text(statusText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("App Group: \(WidgetTemplateConfig.appGroupIdentifier)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: 360, alignment: .topLeading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var previewPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preview")
                .font(.title3.weight(.semibold))

            Text("The card below uses the same shared SwiftUI view as the widget extension.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            WidgetCardView(content: draftContent, layout: .preview)
                .frame(maxWidth: .infinity)
                .frame(height: 320)

            VStack(alignment: .leading, spacing: 8) {
                Text("Widget kind: \(WidgetTemplateConfig.widgetKind)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Supported families: small, medium")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var draftContent: WidgetContent {
        WidgetContent(
            title: sanitized(title, fallback: WidgetContent.placeholder.title),
            message: sanitized(message, fallback: WidgetContent.placeholder.message),
            accent: accent,
            updatedAt: savedAt
        )
    }

    private func loadStoredContent() {
        let content = store.load()
        title = content.title
        message = content.message
        accent = content.accent
        savedAt = content.updatedAt
        statusText = "Loaded the last saved payload from shared storage."
    }

    private func applySample() {
        let sample = WidgetContent.sample
        title = sample.title
        message = sample.message
        accent = sample.accent
        savedAt = sample.updatedAt
        statusText = "Loaded the sample payload. Save if you want it to reach the widget."
    }

    private func save() {
        let content = WidgetContent(
            title: sanitized(title, fallback: WidgetContent.placeholder.title),
            message: sanitized(message, fallback: WidgetContent.placeholder.message),
            accent: accent,
            updatedAt: .now
        )

        do {
            try store.save(content)
            savedAt = content.updatedAt
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetTemplateConfig.widgetKind)
            statusText = "Saved the payload and asked WidgetKit to reload the timeline."
        } catch {
            statusText = "Could not save the payload: \(error.localizedDescription)"
        }
    }

    private func sanitized(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}
