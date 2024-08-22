import Foundation

private final class NoCommaShortDateComponentsFormatter: DateComponentsFormatter, @unchecked Sendable {
    override func string(from components: DateComponents) -> String? {
        let formattedString = super.string(from: components)
        return formattedString?.replacingOccurrences(of: ",", with: "")
    }

    override func string(from ti: TimeInterval) -> String? {
        let formattedString = super.string(from: ti)
        return formattedString?.replacingOccurrences(of: ",", with: "")
    }
}

extension DateComponentsFormatter {
    public static let fullDateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.day, .hour, .minute]
        return formatter
    }()

    public static let noCommaShortDateComponentsFormatter: DateComponentsFormatter = {
        let formatter = NoCommaShortDateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.day, .hour, .minute]
        return formatter
    }()

    public static let briefDateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .brief
        formatter.allowedUnits = [.day, .hour, .minute]
        return formatter
    }()

    public static func travelDurationUnitStyle(interval: TimeInterval) -> DateComponentsFormatter.UnitsStyle {
        return interval < 3600 ? .short : .abbreviated
    }

    public static func travelTimeString(
        _ interval: TimeInterval,
        signed: Bool,
        allowedUnits: NSCalendar.Unit? = nil,
        unitStyle: DateComponentsFormatter.UnitsStyle? = nil
    ) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = allowedUnits ?? [.day, .hour, .minute]
        formatter.unitsStyle = unitStyle ?? travelDurationUnitStyle(interval: interval)
        let timeString = formatter.string(from: signed ? interval : abs(interval)) ?? ""

        if signed, interval >= 0 {
            return String.localizedStringWithFormat("+%@", timeString)
        } else {
            return timeString
        }
    }
}
