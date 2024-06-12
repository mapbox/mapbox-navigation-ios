import Foundation

/// Configures Navigator status polling.
public struct StatusUpdatingSettings {
    /// If new location is not provided during ``updatingPatience`` - status will be polled unconditionally.
    ///
    /// If `nil` - default value will be used.
    public var updatingPatience: TimeInterval?
    /// Interval of unconditional status polling.
    ///
    /// If `nil` - default value will be used.
    public var updatingInterval: TimeInterval?

    /// Creates new ``StatusUpdatingSettings``.
    /// - Parameters:
    ///   - updatingPatience: The patience time before unconditional status polling.
    ///   - updatingInterval: The unconditional polling interval.
    public init(updatingPatience: TimeInterval? = nil, updatingInterval: TimeInterval? = nil) {
        self.updatingPatience = updatingPatience
        self.updatingInterval = updatingInterval
    }
}
