import Foundation
import MapboxNavigationNative

public protocol ElectronicHorizonDelegate: class {

    /**
     Might be called multiple times when the position changes

     - parameter position: Current electronic horizon position (map matched position + e-horizon tree)
     - parameter distances: Map road object id -> RoadObjectDistanceInfo for upcoming road objects
     */
    func didUpdatePosition(_ position: ElectronicHorizonPosition, distances: [String : RoadObjectDistanceInfo])

    /**
     Called when entry to line-like (i.e. which has length != null) road object was detected
     - parameter info: Contains info related to the object
     */

    func roadObjectDidEnter(_ objectEnterExitInfo: RoadObjectEnterExitInfo)

    /**
     Called when exit from line-like (i.e. which has length != null) road object was detected
     - parameter info: Contains info related to the object
     */
    func roadObjectDidExit(_ objectEnterExitInfo: RoadObjectEnterExitInfo)
}
