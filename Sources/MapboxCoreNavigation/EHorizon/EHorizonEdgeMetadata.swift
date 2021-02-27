import Foundation
import MapboxNavigationNative

public struct EHorizonEdgeMetadata {

    /** The bearing in degrees clockwise at the start of the edge. */
    public let heading: Double

    /** The Edge's length in meters. */
    public let length: Double

    /** The edge's functional road class */
    public let functionalRoadClass: RoadClass

    /** The Edge's max speed (m/s) */
    public let speedLimit: Double?

    /** The Edge's average speed (m/s) */
    public let speed: Double

    /** Is the edge a ramp? */
    public let isRamp: Bool

    /** Is the edge a motorway? */
    public let isMotorway: Bool

    /** Is the edge a bridge? */
    public let isBridge: Bool

    /** Is the edge a tunnel? */
    public let isTunnel: Bool

    /** Is the edge a toll road? */
    public let isToll: Bool

    /** The edge's names */
    public let names: [RoadName]

    /** The edge's lane counts */
    public let laneCount: UInt?

    /** The edge's mean elevation */
    public let meanElevation: Double?

    /** The edge's curvature */
    public let curvature: UInt

    /** The edge's country code (ISO-3 format) */
    public let countryCode: String?

    /** The edge's state code */
    public let stateCode: String?

    init(_ native: EdgeMetadata) {
        self.heading = native.heading
        self.length = native.length
        self.functionalRoadClass = RoadClass(native.frc)
        self.speedLimit = native.speedLimit as? Double
        self.speed = native.speed
        self.isRamp = native.isRamp
        self.isMotorway = native.isMotorway
        self.isBridge = native.isBridge
        self.isTunnel = native.isTunnel
        self.isToll = native.isToll
        self.names = native.names.map(RoadName.init)
        self.laneCount = native.laneCount as? UInt
        self.meanElevation = native.meanElevation as? Double
        self.curvature = UInt(native.curvature)
        self.countryCode = native.countryCode
        self.stateCode = native.stateCode
    }
}
