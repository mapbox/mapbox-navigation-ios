
import Foundation
import MapboxNavigationNative
import MapboxDirections

extension AdministrativeRegion {
    init(_ adminInfo: AdminInfo) {
        self.init(countryCode: adminInfo.iso_3166_1, countryCodeAlpha3: adminInfo.iso_3166_1_alpha3)
    }
}

/**
 `BorderCrossingInfo` encapsulates a border crossing, specifying crossing region codes.
 */
public struct BorderCrossing {
    public let from: AdministrativeRegion
    public let to: AdministrativeRegion
    
    init(_ borderCrossing: BorderCrossingInfo) {
        from = AdministrativeRegion(borderCrossing.from)
        to = AdministrativeRegion(borderCrossing.to)
    }
}
