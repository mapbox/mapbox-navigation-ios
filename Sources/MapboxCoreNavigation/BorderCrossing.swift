
import Foundation
import MapboxNavigationNative
import MapboxDirections

extension AdministrativeRegion {
    init(_ adminInfo: AdminInfo) {
        self.init(countryCode: adminInfo.iso_3166_1, countryCodeAlpha3: adminInfo.iso_3166_1_alpha3)
    }
}

/**
 `BorderCrossing` encapsulates a border crossing, specifying crossing region codes.
 */
public struct BorderCrossing {
    public let from: AdministrativeRegion
    public let to: AdministrativeRegion

    /// Initializes a new `BorderCrossing` object.
    /// - Parameters:
    ///   - from: origin administrative region
    ///   - to: destination administrative region
    public init(from: AdministrativeRegion, to: AdministrativeRegion) {
        self.from = from
        self.to = to
    }

    init(_ borderCrossing: BorderCrossingInfo) {
        self.init(from: AdministrativeRegion(borderCrossing.from),
                  to: AdministrativeRegion(borderCrossing.to))
    }
}
