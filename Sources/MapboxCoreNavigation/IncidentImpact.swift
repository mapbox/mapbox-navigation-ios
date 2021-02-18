import MapboxNavigationNative

extension IncidentImpact: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .critical:
            return "critical"
        case .major:
            return "major"
        case .minor:
            return "minor"
        case .low:
            return "low"
        }
    }
}
