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
    
    public static func travelTimeString(_ interval: TimeInterval, signed: Bool) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = interval < 3600 ? .short : .abbreviated
        let timeString = formatter.string(from: interval) ?? ""
        
        return signed ? "\(interval >= 0 ? "+":"")\(timeString)" : timeString
    }
}
