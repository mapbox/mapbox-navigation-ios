import Foundation
import MapboxNavigationNative

/**
 Electronic horizon delegate. Methods are called in the order specified. `didUpdatePosition` might be called
 multiple times after the other methods until a new change to the horizon occurs.
 */
public protocol ElectronicHorizonDelegate: class {

    /**
     Might be called multiple times when the position changes

     - parameter position: Current electronic horizon position (map matched position + e-horizon tree)
     - parameter distances: Map road object identifier -> RoadObjectDistanceInfo for upcoming road objects
     */
    func didUpdatePosition(_ position: ElectronicHorizon.Position, distances: [RoadObjectIdentifier : RoadObjectDistanceInfo])

    /**
     Called when entry to line-like (i.e. which has length != null) road object was detected
     - parameter info: Contains info related to the object
     */

    func didEnterRoadObject(_ objectEnterExitInfo: RoadObjectTransition)

    /**
     Called when exit from line-like (i.e. which has length != null) road object was detected
     - parameter info: Contains info related to the object
     */
    func didExitRoadObject(_ objectEnterExitInfo: RoadObjectTransition)
}
