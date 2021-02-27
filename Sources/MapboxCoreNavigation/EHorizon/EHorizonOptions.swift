import Foundation
import MapboxNavigationNative

public struct EHorizonOptions {

    /** The minimum length of the EHorizon ahead of the current position. */
    public let length: Double

    /** The expansion strategy to be used. */
    public let expansion: UInt

    /** The expansion strategy to be used. */
    public let branchLength: Double

    /**
     * minimum time which should pass between consecutive
     * navigation statuses to update electronic horizon (seconds)
     * if null we update electronic horizon on each navigation status
     */
    public let minTimeDeltaBetweenUpdates: Double?

    public init(length: Double, expansion: UInt, branchLength: Double, minTimeDeltaBetweenUpdates: Double?) {
        self.length = length
        self.expansion = expansion
        self.branchLength = branchLength
        self.minTimeDeltaBetweenUpdates = minTimeDeltaBetweenUpdates
    }

    var nativeOptions: ElectronicHorizonOptions {
        return ElectronicHorizonOptions(
            length: length,
            expansion: UInt8(expansion),
            branchLength: branchLength,
            doNotRecalculateInUncertainState: true,
            minTimeDeltaBetweenUpdates: minTimeDeltaBetweenUpdates as NSNumber?
        )
    }
}
