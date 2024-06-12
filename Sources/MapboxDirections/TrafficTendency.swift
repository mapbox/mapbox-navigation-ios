import Foundation

/// :nodoc:
/// The tendency value conveys the changing state of traffic congestion (increasing, decreasing, constant etc).
///
/// New values could be introduced in the future without an API version change.
public enum TrafficTendency: Int, Codable, CaseIterable, Equatable, Sendable {
    /// Congestion tendency is unknown.
    case unknown = 0
    /// Congestion tendency is not changing.
    case constant = 1
    /// Congestion tendency is increasing.
    case increasing = 2
    /// Congestion tendency is decreasing.
    case decreasing = 3
    /// Congestion tendency is rapidly increasing.
    case rapidlyIncreasing = 4
    /// Congestion tendency is rapidly decreasing.
    case rapidlyDecreasing = 5
}
