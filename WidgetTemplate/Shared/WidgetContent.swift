import SwiftUI

enum WidgetAccent: String, CaseIterable, Codable, Identifiable {
    case teal
    case amber
    case cobalt
    case moss

    var id: String { rawValue }

    var title: String {
        switch self {
        case .teal:
            return "Teal"
        case .amber:
            return "Amber"
        case .cobalt:
            return "Cobalt"
        case .moss:
            return "Moss"
        }
    }

    var backgroundColors: [Color] {
        switch self {
        case .teal:
            return [Color(red: 0.10, green: 0.39, blue: 0.39), Color(red: 0.03, green: 0.12, blue: 0.15)]
        case .amber:
            return [Color(red: 0.78, green: 0.43, blue: 0.17), Color(red: 0.21, green: 0.09, blue: 0.02)]
        case .cobalt:
            return [Color(red: 0.20, green: 0.37, blue: 0.78), Color(red: 0.06, green: 0.10, blue: 0.24)]
        case .moss:
            return [Color(red: 0.26, green: 0.45, blue: 0.24), Color(red: 0.08, green: 0.13, blue: 0.08)]
        }
    }
}

struct WidgetContent: Codable, Equatable {
    var title: String
    var message: String
    var accent: WidgetAccent
    var updatedAt: Date

    static let sample = WidgetContent(
        title: "Daily Focus",
        message: "Protect a single ninety-minute block for the task that moves the most leverage today.",
        accent: .teal,
        updatedAt: .now
    )

    static let placeholder = WidgetContent(
        title: "Your Widget",
        message: "Swap this model and view for the data that matters to you.",
        accent: .cobalt,
        updatedAt: .now
    )
}
