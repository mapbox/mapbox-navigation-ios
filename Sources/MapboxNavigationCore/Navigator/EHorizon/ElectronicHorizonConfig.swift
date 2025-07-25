import CoreLocation
import Foundation
import MapboxNavigationNative_Private

/// Defines options for emitting ``Foundation/NSNotification/Name/electronicHorizonDidUpdatePosition``,
/// ``Foundation/NSNotification/Name/electronicHorizonDidEnterRoadObject``, and
/// ``Foundation/NSNotification/Name/electronicHorizonDidExitRoadObject`` notifications while active guidance or free
/// drive is in progress.
///
/// - Note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to
/// changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox Terms
/// of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and require
/// customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level of use of the
/// feature.
public struct ElectronicHorizonConfig: Equatable, Sendable {
    /// The minimum length of the electronic horizon ahead of the current position, measured in meters.
    public let length: CLLocationDistance

    /// The number of levels of branches by which to expand the horizon.
    ///
    /// A value of 0 results in only the most probable path (MPP). A value of 1 adds paths branching out directly from
    /// the MPP, a value of 2 adds paths branching out from those paths, and so on. Only 0, 1, and 2 are usable in terms
    /// of performance.
    public let expansionLevel: UInt

    /// Minimum length of side branches, measured in meters.
    public let branchLength: CLLocationDistance

    /// Minimum time which should pass between consecutive navigation statuses to update electronic horizon (seconds).
    /// If `nil` we update electronic horizon on each navigation status.
    public let minimumTimeIntervalBetweenUpdates: TimeInterval?

    public init(
        length: CLLocationDistance,
        expansionLevel: UInt,
        branchLength: CLLocationDistance,
        minTimeDeltaBetweenUpdates: TimeInterval?
    ) {
        self.length = length
        self.expansionLevel = expansionLevel
        self.branchLength = branchLength
        self.minimumTimeIntervalBetweenUpdates = minTimeDeltaBetweenUpdates
    }
}

extension MapboxNavigationNative_Private.ElectronicHorizonOptions {
    convenience init(_ options: ElectronicHorizonConfig) {
        self.init(
            length: options.length,
            expansion: UInt8(options.expansionLevel),
            branchLength: options.branchLength,
            doNotRecalculateInUncertainState: true,
            minTimeDeltaBetweenUpdates: options.minimumTimeIntervalBetweenUpdates as NSNumber?,
            alertsService: nil,
            enableEnhancedDataAlongEH: false // TODO: (NAVIOS-2147) Expose to public if needed
        )
    }
}
