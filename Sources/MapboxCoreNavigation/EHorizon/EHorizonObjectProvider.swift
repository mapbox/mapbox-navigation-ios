import Foundation
import MapboxNavigationNative

public enum EHorizonObjectProvider {

    /** road object was provided via Mapbox services */
    case mapbox

    /** road object was added by user(via `RoadObjectsStore.addCustomRoadObject`) */
    case custom

    init(_ native: RoadObjectProvider) {
        switch native {
        case .mapbox:
            self = .mapbox
        case .custom:
            self = .custom
        }
    }
}
