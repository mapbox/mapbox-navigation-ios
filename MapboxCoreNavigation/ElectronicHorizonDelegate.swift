import Foundation
import MapboxNavigationNative

public protocol ElectronicHorizonDelegate: class {
    func electronicHorizonDidUpdate(_ electronicHorizon: ElectronicHorizon, type: ElectronicHorizonResultType)
    func didUpdatePosition(_ position: GraphPosition)
}
