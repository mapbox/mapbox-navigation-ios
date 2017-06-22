extension Date {
    var ISO8601: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.timeZone = TimeZone(abbreviation: TimeZone.current.abbreviation() ?? "GMT")
        return formatter.string(from: self)
    }
}
