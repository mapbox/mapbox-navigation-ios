
import Foundation
import MapboxNavigationNative
import MapboxDirections

extension TollCollection {
    init(_ tollInfo: RouteAlertTollCollectionInfo) {
        switch tollInfo.type {
        case .kTollBooth:
            self.init(type: .booth)
        case .kTollGantry:
            self.init(type: .gantry)
        }
    }
}
