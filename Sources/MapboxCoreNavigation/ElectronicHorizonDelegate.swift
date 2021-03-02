import Foundation
import MapboxNavigationNative

public protocol ElectronicHorizonDelegate: class {
    func electronicHorizonDidUpdate(_ electronicHorizon: ElectronicHorizon, type: ElectronicHorizonResultType)
    func didUpdatePosition(_ position: GraphPosition, distances: [String : RoadObjectDistanceInfo])
    func roadObjectEnter(roadObjectId: String, fromStart: Bool)
    func roadObjectExit(roadObjectId: String, fromEnd: Bool)
}
