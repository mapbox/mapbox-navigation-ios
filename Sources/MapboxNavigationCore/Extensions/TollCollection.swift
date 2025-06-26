
import Foundation
import MapboxDirections
import MapboxNavigationNative_Private

extension TollCollection {
    init?(_ tollInfo: TollCollectionInfo) {
        switch tollInfo.type {
        case .tollBooth:
            self.init(type: .booth, name: tollInfo.name)
        case .tollGantry:
            self.init(type: .gantry, name: tollInfo.name)
        @unknown default:
            assertionFailure("Unknown TollCollectionInfo type.")
            return nil
        }
    }
}
