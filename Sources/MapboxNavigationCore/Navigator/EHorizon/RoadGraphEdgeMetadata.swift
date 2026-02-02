import CoreLocation
import Foundation
import MapboxDirections
import MapboxNavigationNative_Private

extension RoadGraph.Edge {
    /// Indicates how many directions the user may travel along an edge.
    ///
    /// - Note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to
    /// changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox
    /// Terms of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and
    /// require customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level
    /// of use of the feature.
    public enum Directionality: Sendable {
        /// The user may only travel in one direction along the edge.
        case oneWay
        /// The user may travel in either direction along the edge.
        case bothWays
    }

    /// Edge metadata
    public struct Metadata: Sendable {
        // MARK: Geographical & Physical Characteristics

        /// The bearing in degrees clockwise at the start of the edge.
        public let heading: CLLocationDegrees

        /// The edge’s length in meters.
        public let length: CLLocationDistance

        /// The edge’s mean elevation, measured in meters.
        public let altitude: CLLocationDistance?

        /// The edge’s curvature.
        public let curvature: UInt

        // MARK: Road Classification

        /// Is the edge a bridge?
        public let isBridge: Bool

        /// Is the edge a ferry?
        public let isFerry: Bool

        /// Is the edge a roundabout?
        public let isRoundabout: Bool

        /// The edge’s general road classes.
        public let roadClasses: RoadClasses

        /// The edge’s functional road class, according to the [Mapbox Streets
        /// source](https://docs.mapbox.com/vector-tiles/reference/mapbox-streets-v8/#road), version 8.
        public let mapboxStreetsRoadClass: MapboxStreetsRoadClass

        // MARK: Legal definitions

        /// The edge's names
        public let names: [RoadName]

        /// The ISO 3166-1 alpha-2 code of the country where this edge is located.
        public let countryCode: String?

        /// The ISO 3166-1 alpha-3 code of the country where this edge is located.
        public let countryCodeISO3: String?

        /// The ISO 3166-2 code of the country subdivision where this edge is located.
        public let regionCode: String?

        // MARK: Road Regulations

        /// Indicates how many directions the user may travel along the edge.
        public let directionality: Directionality

        /// The edge’s maximum speed limit.
        public let speedLimit: Measurement<UnitSpeed>?

        /// The user’s expected average speed along the edge, measured in meters per second.
        public let speed: CLLocationSpeed

        /// The expected average speed along the edge when there is no traffic.
        /// Measured in meters per second. `nil` if unknown.
        public let freeFlowSpeed: CLLocationSpeed?

        /// The expected average speed along the edge when there is traffic.
        /// Measured in meters per second. `nil` if unknown.
        public let constrainedFlowSpeed: CLLocationSpeed?

        /// Indicates which side of a bidirectional road on which the driver must be driving. Also referred to as the
        /// rule of the road.
        public let drivingSide: DrivingSide

        /// The number of parallel traffic lanes along the edge.
        public let laneCount: UInt?

        /// `true` if edge is considered to be in an urban area, `false` otherwise.
        public let isUrban: Bool

        /// Edge's surface type.
        public let surface: RoadGraph.RoadSurface

        /// Whether the edge is a part of service area or rest area or none.
        public let sapaType: RoadGraph.SapaType

        /// Initializes a new edge ``RoadGraph/Edge/Metadata`` object.
        public init(
            heading: CLLocationDegrees,
            length: CLLocationDistance,
            roadClasses: RoadClasses,
            mapboxStreetsRoadClass: MapboxStreetsRoadClass,
            speedLimit: Measurement<UnitSpeed>?,
            speed: CLLocationSpeed,
            freeFlowSpeed: CLLocationSpeed?,
            constrainedFlowSpeed: CLLocationSpeed?,
            isBridge: Bool,
            isFerry: Bool,
            isRoundabout: Bool,
            names: [RoadName],
            laneCount: UInt?,
            altitude: CLLocationDistance?,
            curvature: UInt,
            countryCode: String?,
            countryCodeISO3: String?,
            regionCode: String?,
            drivingSide: DrivingSide,
            directionality: Directionality,
            isUrban: Bool,
            surface: RoadGraph.RoadSurface,
            sapaType: RoadGraph.SapaType
        ) {
            self.heading = heading
            self.length = length
            self.roadClasses = roadClasses
            self.mapboxStreetsRoadClass = mapboxStreetsRoadClass
            self.speedLimit = speedLimit
            self.speed = speed
            self.freeFlowSpeed = freeFlowSpeed
            self.constrainedFlowSpeed = constrainedFlowSpeed
            self.isBridge = isBridge
            self.isFerry = isFerry
            self.isRoundabout = isRoundabout
            self.names = names
            self.laneCount = laneCount
            self.altitude = altitude
            self.curvature = curvature
            self.countryCode = countryCode
            self.countryCodeISO3 = countryCodeISO3
            self.regionCode = regionCode
            self.drivingSide = drivingSide
            self.directionality = directionality
            self.isUrban = isUrban
            self.surface = surface
            self.sapaType = sapaType
        }

        /// Initializes a new edge ``RoadGraph/Edge/Metadata`` object.
        init(
            heading: CLLocationDegrees,
            length: CLLocationDistance,
            roadClasses: RoadClasses,
            mapboxStreetsRoadClass: MapboxStreetsRoadClass,
            speedLimit: Measurement<UnitSpeed>?,
            speed: CLLocationSpeed,
            freeFlowSpeed: CLLocationSpeed?,
            constrainedFlowSpeed: CLLocationSpeed?,
            isBridge: Bool,
            isFerry: Bool,
            isRoundabout: Bool,
            names: [RoadName],
            laneCount: UInt?,
            altitude: CLLocationDistance?,
            curvature: UInt,
            countryCode: String?,
            countryCodeISO3: String?,
            regionCode: String?,
            drivingSide: DrivingSide,
            directionality: Directionality,
            surface: RoadGraph.RoadSurface,
            sapaType: RoadGraph.SapaType
        ) {
            self.init(
                heading: heading,
                length: length,
                roadClasses: roadClasses,
                mapboxStreetsRoadClass: mapboxStreetsRoadClass,
                speedLimit: speedLimit,
                speed: speed,
                freeFlowSpeed: freeFlowSpeed,
                constrainedFlowSpeed: constrainedFlowSpeed,
                isBridge: isBridge,
                isFerry: isFerry,
                isRoundabout: isRoundabout,
                names: names,
                laneCount: laneCount,
                altitude: altitude,
                curvature: curvature,
                countryCode: countryCode,
                countryCodeISO3: countryCodeISO3,
                regionCode: regionCode,
                drivingSide: drivingSide,
                directionality: directionality,
                isUrban: false,
                surface: surface,
                sapaType: sapaType
            )
        }

        init(_ native: EdgeMetadata) {
            self.heading = native.heading
            self.length = native.length
            self.mapboxStreetsRoadClass = MapboxStreetsRoadClass(native.frc, isRamp: native.ramp)
            if let speedLimitValue = native.speedLimit as? Double {
                // TODO: Convert to miles per hour as locally appropriate.
                self.speedLimit = Measurement(
                    value: speedLimitValue == 0.0 ? .infinity : speedLimitValue,
                    unit: UnitSpeed.metersPerSecond
                ).converted(to: .kilometersPerHour)
            } else {
                self.speedLimit = nil
            }
            self.speed = native.speed
            self.freeFlowSpeed = native.freeFlowSpeed.map(\.doubleValue)
            self.constrainedFlowSpeed = native.constrainedFlowSpeed.map(\.doubleValue)

            var roadClasses: RoadClasses = []
            if native.motorway {
                roadClasses.update(with: .motorway)
            }
            if native.tunnel {
                roadClasses.update(with: .tunnel)
            }
            if native.toll {
                roadClasses.update(with: .toll)
            }
            self.roadClasses = roadClasses

            self.isBridge = native.bridge
            self.isFerry = native.ferry
            self.isRoundabout = native.roundabout
            self.names = native.names.compactMap(RoadName.init)
            self.laneCount = native.laneCount as? UInt
            self.altitude = native.meanElevation as? Double
            self.curvature = UInt(native.curvature)
            self.countryCode = native.countryCodeIso2
            self.countryCodeISO3 = native.countryCodeIso3
            self.regionCode = native.stateCode
            self.drivingSide = native.isRightHandTraffic ? .right : .left
            self.directionality = native.isOneway ? .oneWay : .bothWays
            self.isUrban = native.isUrban
            self.surface = .init(native.surface)
            self.sapaType = .init(native.sapaType)
        }
    }
}
