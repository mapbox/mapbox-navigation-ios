import Foundation

/// An object describing time zone relevant information.
public struct TimeZoneInformation: Codable, Equatable, Sendable {
    /// A unique string that specifies a time zone in the format of Region/Location,
    /// for example `America/New_York` or `Europe/Paris`, as defined by the IANA Time Zone Database.
    public let identifier: String
    /// The difference in hours and minutes between a specific time zone and Coordinated Universal Time (UTC),
    /// for example -05:00 for Eastern Standard Time or +01:00 for Central European Time.
    public let offset: String
    /// _Optional_.  A short, commonly recognized abbreviation for a time zone,
    /// often used for display purposes, for example EST for Eastern Standard Time or CET for Central European Time.
    /// Note that this field may not always be available.
    public let abbreviation: String?
    /// Convenience property to transform entity to the Foundation `TimeZone` one.
    public var timeZone: TimeZone? {
        TimeZone(identifier: identifier)
    }
}
