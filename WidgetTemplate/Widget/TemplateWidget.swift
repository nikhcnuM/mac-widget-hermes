import SwiftUI
import WidgetKit

private struct TemplateTimelineProvider: TimelineProvider {
    private let store = WidgetContentStore()

    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: .now, content: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        completion(WidgetEntry(date: .now, content: store.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let entry = WidgetEntry(date: .now, content: store.load())
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}

private struct WidgetEntry: TimelineEntry {
    let date: Date
    let content: WidgetContent
}

struct MacWidgetBoilerplateWidget: Widget {
    let kind = WidgetTemplateConfig.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TemplateTimelineProvider()) { entry in
            MacWidgetBoilerplateWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("Hermes")
        .description("Shows the latest Hermes companion response.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct MacWidgetBoilerplateWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    let entry: WidgetEntry

    var body: some View {
        WidgetCardView(
            content: entry.content,
            layout: family == .systemSmall ? .small : .medium
        )
    }
}
