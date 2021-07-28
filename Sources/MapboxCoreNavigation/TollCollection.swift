
import Foundation
import MapboxNavigationNative
import MapboxDirections

extension TollCollection {
    init(_ tollInfo: TollCollectionInfo) {
        switch tollInfo.type {
        case .tollBooth:
            self.init(type: .booth)
        case .tollGantry:
            self.init(type: .gantry)
        @unknown default:
            fatalError("Unknown TollCollectionInfo type.")
        }
    }
}
