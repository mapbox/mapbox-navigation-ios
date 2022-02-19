import Foundation

extension Date {
    
    func intervalUntilTimeOfDayChanges(sunrise: Date, sunset: Date) -> TimeInterval? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: self)
        guard let date = calendar.date(from: components) else {
            return nil
        }
        
        if isNighttime(sunrise: sunrise, sunset: sunset) {
            let sunriseComponents = calendar.dateComponents([.hour, .minute, .second], from: sunrise)
            guard let sunriseDate = calendar.date(from: sunriseComponents) else {
                return nil
            }
            let interval = sunriseDate.timeIntervalSince(date)
            return interval >= 0 ? interval : (interval + 24 * 3600)
        } else {
            let sunsetComponents = calendar.dateComponents([.hour, .minute, .second], from: sunset)
            guard let sunsetDate = calendar.date(from: sunsetComponents) else {
                return nil
            }
            return sunsetDate.timeIntervalSince(date)
        }
    }
    
    func isNighttime(sunrise: Date, sunset: Date) -> Bool {
        let calendar = Calendar.current
        
        let currentSecondsFromMidnight =
        calendar.component(.hour, from: self) * 3600 +
        calendar.component(.minute, from: self) * 60 +
        calendar.component(.second, from: self)
        
        let sunriseSecondsFromMidnight =
        calendar.component(.hour, from: sunrise) * 3600 +
        calendar.component(.minute, from: sunrise) * 60 +
        calendar.component(.second, from: sunrise)
        
        let sunsetSecondsFromMidnight =
        calendar.component(.hour, from: sunset) * 3600 +
        calendar.component(.minute, from: sunset) * 60 +
        calendar.component(.second, from: sunset)
        
        return currentSecondsFromMidnight < sunriseSecondsFromMidnight ||
        currentSecondsFromMidnight > sunsetSecondsFromMidnight
    }
}
