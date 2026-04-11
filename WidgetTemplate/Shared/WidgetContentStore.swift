import Foundation

struct WidgetContentStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults? = nil) {
        self.defaults = defaults ?? UserDefaults(suiteName: WidgetTemplateConfig.appGroupIdentifier) ?? .standard
    }

    func load() -> WidgetContent {
        guard let data = defaults.data(forKey: WidgetTemplateConfig.contentKey) else {
            return .sample
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return (try? decoder.decode(WidgetContent.self, from: data)) ?? .sample
    }

    func save(_ content: WidgetContent) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]

        let data = try encoder.encode(content)
        defaults.set(data, forKey: WidgetTemplateConfig.contentKey)
    }
}
