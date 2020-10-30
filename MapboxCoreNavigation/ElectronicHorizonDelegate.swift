import Foundation
import MapboxNavigationNative

public protocol ElectronicHorizonDelegate: class {
    func electronicHorizonDidUpdate(_ electronicHorizon: ElectronicHorizon)
    func didUpdatePosition(_ position: GraphPosition)
}
