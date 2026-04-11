import SwiftUI

enum WidgetCardLayout: Equatable {
    case small
    case medium
    case preview

    var titleFont: Font {
        switch self {
        case .small:
            return .headline
        case .medium:
            return .title3
        case .preview:
            return .title2
        }
    }

    var bodyFont: Font {
        switch self {
        case .small:
            return .caption
        case .medium:
            return .body
        case .preview:
            return .body
        }
    }

    var padding: CGFloat {
        switch self {
        case .small:
            return 16
        case .medium:
            return 18
        case .preview:
            return 22
        }
    }

    var messageLimit: Int {
        switch self {
        case .small:
            return 4
        case .medium:
            return 5
        case .preview:
            return 6
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .small:
            return 24
        case .medium:
            return 26
        case .preview:
            return 30
        }
    }

    var timestampFont: Font {
        switch self {
        case .small:
            return .caption2
        case .medium:
            return .caption
        case .preview:
            return .callout
        }
    }
}

struct WidgetCardView: View {
    let content: WidgetContent
    let layout: WidgetCardLayout

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: layout.cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: content.accent.backgroundColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: layout.cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Text(content.title)
                        .font(layout.titleFont.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(layout == .small ? 2 : 1)

                    Spacer(minLength: 0)

                    Text(content.accent.title)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.16), in: Capsule())
                        .foregroundStyle(.white.opacity(0.92))
                }

                Text(content.message)
                    .font(layout.bodyFont)
                    .foregroundStyle(.white.opacity(0.92))
                    .lineSpacing(2)
                    .lineLimit(layout.messageLimit)

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(layout.timestampFont.weight(.semibold))

                    Text(content.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(layout.timestampFont)
                }
                .foregroundStyle(.white.opacity(0.74))
            }
            .padding(layout.padding)
        }
    }
}
