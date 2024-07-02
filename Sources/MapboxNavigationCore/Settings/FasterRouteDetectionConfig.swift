import CoreLocation
import Foundation

/// Options to configure fetching, detecting, and accepting a faster route during active guidance.
public struct FasterRouteDetectionConfig: Equatable {
    public static func == (lhs: FasterRouteDetectionConfig, rhs: FasterRouteDetectionConfig) -> Bool {
        guard lhs.fasterRouteApproval == rhs.fasterRouteApproval,
              lhs.proactiveReroutingInterval == rhs.proactiveReroutingInterval,
              lhs.minimumRouteDurationRemaining == rhs.minimumRouteDurationRemaining,
              lhs.minimumManeuverOffset == rhs.minimumManeuverOffset
        else {
            return false
        }

        switch (lhs.customFasterRouteProvider, rhs.customFasterRouteProvider) {
        case (.none, .none), (.some(_), .some(_)):
            return true
        default:
            return false
        }
    }

    public typealias FasterRouteApproval = ApprovalModeAsync<(CLLocation, NavigationRoute)>

    public var fasterRouteApproval: FasterRouteApproval
    public var proactiveReroutingInterval: TimeInterval
    public var minimumRouteDurationRemaining: TimeInterval
    public var minimumManeuverOffset: TimeInterval
    public var customFasterRouteProvider: (any FasterRouteProvider)?

    public init(
        fasterRouteApproval: FasterRouteApproval = .automatically,
        proactiveReroutingInterval: TimeInterval = 120,
        minimumRouteDurationRemaining: TimeInterval = 600,
        minimumManeuverOffset: TimeInterval = 70,
        customFasterRouteProvider: (any FasterRouteProvider)? = nil
    ) {
        self.fasterRouteApproval = fasterRouteApproval
        self.proactiveReroutingInterval = proactiveReroutingInterval
        self.minimumRouteDurationRemaining = minimumRouteDurationRemaining
        self.minimumManeuverOffset = minimumManeuverOffset
        self.customFasterRouteProvider = customFasterRouteProvider
    }
}
