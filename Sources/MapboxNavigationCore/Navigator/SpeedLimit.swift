import Foundation
import MapboxDirections

public struct SpeedLimit: Equatable, @unchecked Sendable {
    public let value: Measurement<UnitSpeed>?
    public let signStandard: SignStandard
}
