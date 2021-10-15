import Foundation
import CoreLocation
import MapboxDirections
import MapboxNavigationNative

extension RoadGraph.Edge {
    /**
     Indicates how many directions the user may travel along an edge.
     
     - note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox Terms of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and require customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level of use of the feature.
     */
    public enum Directionality {
        /// The user may only travel in one direction along the edge.
        case oneWay
        /// The user may travel in either direction along the edge.
        case bothWays
    }

    /** Edge metadata */
    public struct Metadata {

        // MARK: Geographical & Physical Characteristics
        
        /** The bearing in degrees clockwise at the start of the edge. */
        public let heading: CLLocationDegrees

        /** The edge’s length in meters. */
        public let length: CLLocationDistance
        
        /** The edge’s mean elevation, measured in meters. */
        public let altitude: CLLocationDistance?

        /** The edge’s curvature. */
        public let curvature: UInt

        // MARK: Road Classification
        
        /** Is the edge a bridge? */
        public let isBridge: Bool
        
        /** The edge’s general road classes. */
        public let roadClasses: RoadClasses
        
        /** The edge’s functional road class, according to the [Mapbox Streets source](https://docs.mapbox.com/vector-tiles/reference/mapbox-streets-v8/#road), version 8. */
        public let mapboxStreetsRoadClass: MapboxStreetsRoadClass

        
        // MARK: Legal definitions
        
        /** The edge's names */
        public let names: [RoadName]
        
        /** The ISO 3166-1 alpha-2 code of the country where this edge is located. */
        public let countryCode: String?

        /** The ISO 3166-2 code of the country subdivision where this edge is located. */
        public let regionCode: String?
        
        // MARK: Road Regulations
        
        /** Indicates how many directions the user may travel along the edge. */
        public let directionality: Directionality
        
        /** The edge’s maximum speed limit. */
        public let speedLimit: Measurement<UnitSpeed>?

        /** The user’s expected average speed along the edge, measured in meters per second. */
        public let speed: CLLocationSpeed
        
        /** Indicates which side of a bidirectional road on which the driver must be driving. Also referred to as the rule of the road. */
        public let drivingSide: DrivingSide
        
        /** The number of parallel traffic lanes along the edge. */
        public let laneCount: UInt?
        
        /**
         Initializes a new edge `Metadata` object.
         */
        public init(heading: CLLocationDegrees,
                    length: CLLocationDistance,
                    roadClasses: RoadClasses,
                    mapboxStreetsRoadClass: MapboxStreetsRoadClass,
                    speedLimit: Measurement<UnitSpeed>?,
                    speed: CLLocationSpeed,
                    isBridge: Bool,
                    names: [RoadName],
                    laneCount: UInt?,
                    altitude: CLLocationDistance?,
                    curvature: UInt,
                    countryCode: String?,
                    regionCode: String?,
                    drivingSide: DrivingSide,
                    directionality: Directionality) {
            self.heading = heading
            self.length = length
            self.roadClasses = roadClasses
            self.mapboxStreetsRoadClass = mapboxStreetsRoadClass
            self.speedLimit = speedLimit
            self.speed = speed
            self.isBridge = isBridge
            self.names = names
            self.laneCount = laneCount
            self.altitude = altitude
            self.curvature = curvature
            self.countryCode = countryCode
            self.regionCode = regionCode
            self.drivingSide = drivingSide
            self.directionality = directionality
        }

        init(_ native: EdgeMetadata) {
            heading = native.heading
            length = native.length
            mapboxStreetsRoadClass = MapboxStreetsRoadClass(native.frc, isRamp: native.isRamp)
            if let speedLimitValue = native.speedLimit as? Double {
                // TODO: Convert to miles per hour as locally appropriate.
                speedLimit = Measurement(value: speedLimitValue == 0.0 ? .infinity : speedLimitValue,
                                         unit: UnitSpeed.metersPerSecond).converted(to: .kilometersPerHour)
            } else {
                speedLimit = nil
            }
            speed = native.speed
            
            var roadClasses: RoadClasses = []
            if native.isMotorway {
                roadClasses.update(with: .motorway)
            }
            if native.isTunnel {
                roadClasses.update(with: .tunnel)
            }
            if native.isToll {
                roadClasses.update(with: .toll)
            }
            self.roadClasses = roadClasses
            
            isBridge = native.isBridge
            names = native.names.map(RoadName.init)
            laneCount = native.laneCount as? UInt
            altitude = native.meanElevation as? Double
            curvature = UInt(native.curvature)
            countryCode = native.countryCodeIso2
            regionCode = native.stateCode
            drivingSide = native.isIsRightHandTraffic ? .right : .left
            directionality = native.isIsOneway ? .oneWay : .bothWays
        }
    }
}
