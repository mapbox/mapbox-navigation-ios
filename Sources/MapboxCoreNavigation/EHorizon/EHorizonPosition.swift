import Foundation
import MapboxNavigationNative

public class EHorizonPosition {

    public let position: EHorizonGraphPosition

    public let tree: EHorizon

    public let type: EHorizonResultType

    init(_ native: ElectronicHorizonPosition) {
        self.position = EHorizonGraphPosition(try! native.position())
        self.tree = EHorizon(try! native.tree())
        self.type = EHorizonResultType(try! native.type())
    }
}
