import Foundation

final class AdaptiveDateFormatter: Formatter {
    @MainActor
    static let `default` = AdaptiveDateFormatter()

    private static let relativeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.formattingContext = .middleOfSentence
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()

    override func string(for obj: Any?) -> String? {
        guard let date = obj as? Date else { return nil }
        return string(from: date)
    }

    func string(from date: Date) -> String {
        // Reproduce the logic from
        // https://github.com/grishka/Smithereen/blob/2162656ff07558c766a50cf7366306bc9e836e72/src/main/java/smithereen/lang/Lang.java#L216
        let now = Date()
        let diffInSeconds = date.distance(to: now)
        switch diffInSeconds {
        case -1 ..< 60:
            return String(localized: "just now")
        case 60 ..< 3600, -3600 ..< -1:
            return date.formatted(
                Date.RelativeFormatStyle(
                    presentation: .numeric,
                    unitsStyle: .wide,
                    capitalizationContext: .middleOfSentence,
                )
            )
        case -2*24*60*60 ..< 2*24*60*60:
            return Self.relativeDateFormatter.string(from: date)
        default:
            let calendar = Calendar.autoupdatingCurrent
            let year = calendar.component(.year, from: date)
            let currentYear = calendar.component(.year, from: now)
            let formatStyle = Date.FormatStyle(capitalizationContext: .middleOfSentence)
                .day()
                .month(.wide)
                .hour(.conversationalDefaultDigits(amPM: .abbreviated))
                .minute()
            if year == currentYear {
                return date.formatted(formatStyle)
            } else {
                return date.formatted(formatStyle.year())
            }
        }
    }
}

