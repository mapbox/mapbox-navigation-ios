
import Foundation
import MapboxNavigationNative
import MapboxDirections

extension AdministrationRegion {
    init(_ adminInfo: RouteAlertAdminInfo) {
        self.init(countryCode: adminInfo.iso_3166_1, countryCodeAlpha3: adminInfo.iso_3166_1_alpha3)
    }
}

/**
 `BorderCrossingInfo` encapsulates a border crossing, specifying crossing region codes.
 */
public struct BorderCrossingInfo {
    public let from: AdministrationRegion
    public let to: AdministrationRegion
    
    init(_ borderCrossing: RouteAlertBorderCrossingInfo) {
        from = AdministrationRegion(borderCrossing.from)
        to = AdministrationRegion(borderCrossing.to)
    }
}
