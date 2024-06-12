import MapboxMaps

/// Defines camera behavior mode.
public enum NavigationCameraState: Equatable, Sendable {
    /// The camera position and other attributes are idle.
    case idle
    /// The camera is following user position.
    case following
    /// The camera is previewing some extended, non-point object.
    case overview
}

extension NavigationCameraState: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .idle:
            return "idle"
        case .following:
            return "following"
        case .overview:
            return "overview"
        }
    }
}
