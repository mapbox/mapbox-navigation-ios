import Foundation
import CoreLocation
import MapboxDirections
import MapboxNavigationNative

extension ElectronicHorizon.Edge {

    /** Edge metadata */
    public struct Metadata {

        /** The bearing in degrees clockwise at the start of the edge. */
        public let heading: CLLocationDegrees

        /** The Edge's length in meters. */
        public let length: CLLocationDistance

        /** The edge's functional road class */
        public let functionalRoadClass: MapboxStreetsRoadClass

        /** The edge’s maximum speed limit. */
        public let speedLimit: Measurement<UnitSpeed>?

        /** The Edge's average speed (m/s) */
        public let speed: CLLocationSpeed

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
        public let meanElevation: CLLocationDistance?

        /** The edge's curvature */
        public let curvature: UInt

        /** The edge's country code (ISO 3166-1 alpha-3 format) */
        public let countryCode: String?

        /** The edge's region code (ISO 3166-2 format) */
        public let regionCode: String?

        init(_ native: EdgeMetadata) {
            self.heading = native.heading
            self.length = native.length
            self.functionalRoadClass = MapboxStreetsRoadClass(native.frc)
            if let speedLimitValue = native.speedLimit as? Double {
                // TODO: Convert to miles per hour as locally appropriate.
                self.speedLimit = Measurement(value: speedLimitValue, unit: UnitSpeed.metersPerSecond).converted(to: .kilometersPerHour)
            } else {
                self.speedLimit = nil
            }
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
            self.regionCode = native.stateCode
        }
    }
}
