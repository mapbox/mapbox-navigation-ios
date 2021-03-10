import Foundation
import MapboxNavigationNative

public protocol EHorizonDelegate: class {

    /**
     Might be called multiple times when the position changes

     - parameter position: Current electronic horizon position (map matched position + e-horizon tree)
     - parameter distances: Map road object identifier -> RoadObjectDistanceInfo for upcoming road objects
     */
    func didUpdatePosition(_ position: EHorizonPosition, distances: [RoadObjectIdentifier : EHorizonObjectDistanceInfo])

    /**
     Called when entry to line-like (i.e. which has length != null) road object was detected
     - parameter info: Contains info related to the object
     */

    func didEnterObject(_ objectEnterExitInfo: EHorizonObjectEnterExitInfo)

    /**
     Called when exit from line-like (i.e. which has length != null) road object was detected
     - parameter info: Contains info related to the object
     */
    func didExitRoadObject(_ objectEnterExitInfo: EHorizonObjectEnterExitInfo)
}
