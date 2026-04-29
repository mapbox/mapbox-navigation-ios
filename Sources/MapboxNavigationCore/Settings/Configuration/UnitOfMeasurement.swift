import Foundation

/// Holds available types of measurement units.
@available(*, deprecated, message: "Use `UnitMeasurementSystem` instead.")
public enum UnitOfMeasurement: Equatable, Sendable {
    /// Allows SDK to pick proper units.
    case auto
    /// Selects imperial units as default.
    case imperial
    /// Selects metric units as default.
    case metric
}
