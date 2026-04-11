import Foundation

enum WidgetTemplateConfig {
    static let appGroupIdentifierKey = "AppGroupIdentifier"
    static let widgetKind = "MacWidgetBoilerplateWidget"
    static let contentKey = "widgetContent"

    static var appGroupIdentifier: String {
        guard
            let identifier = Bundle.main.object(forInfoDictionaryKey: appGroupIdentifierKey) as? String,
            !identifier.isEmpty
        else {
            return "group.com.example.macwidgetboilerplate"
        }

        return identifier
    }
}
