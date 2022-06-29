import Foundation

extension DateComponentsFormatter {
    public static let fullDateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.day, .hour, .minute]
        return formatter
    }()

    public static let shortDateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
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
    
    public static func travelTimeString(_ interval: TimeInterval,
                                        signed: Bool,
                                        unitStyle: DateComponentsFormatter.UnitsStyle?) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = unitStyle ?? travelDurationUnitStyle(interval: interval)
        let timeString = formatter.string(from: signed ? interval : abs(interval)) ?? ""
        
        if signed && interval >= 0 {
                return String.localizedStringWithFormat(NSLocalizedString("EXPLICITLY_POSITIVE_NUMBER",
                                                                          bundle: .mapboxNavigation,
                                                                          value: "+%@",
                                                                          comment: "Number string with an explicit '+' sign."),
                                                        timeString)
        } else {
            return timeString
        }
    }
}
