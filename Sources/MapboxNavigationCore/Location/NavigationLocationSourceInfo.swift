import CoreLocation
import Foundation

/// Information about the source that provides the location.
public struct NavigationLocationSourceInfo: Codable, Sendable, Equatable {
    /// A Boolean value that indicates whether the system generates the location using on-device software simulation.
    public let isSimulatedBySoftware: Bool
    /// A Boolean value that indicates whether the system receives the location from an external accessory.
    public let isProducedByAccessory: Bool

    /// Information about the source that provides the location.
    /// - Parameters:
    ///   - isSimulatedBySoftware: A Boolean value that indicates whether the system generates the location using
    /// on-device software simulation.
    ///   - isProducedByAccessory: A Boolean value that indicates whether the system receives the location from an
    /// external accessory.
    public init(isSimulatedBySoftware: Bool, isProducedByAccessory: Bool) {
        self.isSimulatedBySoftware = isSimulatedBySoftware
        self.isProducedByAccessory = isProducedByAccessory
    }
}

@available(iOS 15.0, *)
extension NavigationLocationSourceInfo {
    init(_ sourceInfo: CLLocationSourceInformation) {
        self.isSimulatedBySoftware = sourceInfo.isSimulatedBySoftware
        self.isProducedByAccessory = sourceInfo.isProducedByAccessory
    }

    var clSourceInfo: CLLocationSourceInformation {
        CLLocationSourceInformation(
            softwareSimulationState: isSimulatedBySoftware,
            andExternalAccessoryState: isProducedByAccessory
        )
    }
}
