import MapboxNavigationNative_Private

extension RoadGraph.Edge {
    /// Describes specific infrastructure object, located along the Edge.
    public struct RoadItem: Hashable, Equatable, Sendable {
        /// The type of the road item.
        ///
        /// Describes, what that actually is.
        public let kind: Kind
        /// The location of the road item, relative to the road.
        ///
        /// May not be applied to all of the possible ``Type``s.
        public let location: Location?
        /// The lanes of the road item.
        ///
        /// Available only if `location` is `aboveLane`.
        public let lanes: [Int]
        /// An additional numeric value, when approriate for the current road item `kind`.
        ///
        /// For example: speed limit value for a speed limit sign or a speed camera,
        /// slope degrees value for steep ascent/descent signs, etc.
        public let value: Int?

        init(_ native: MapboxNavigationNative_Private.RoadItem) {
            self.kind = .init(native.type)
            self.location = native.location.map { Location($0.intValue) }
            self.lanes = native.lanes.map(\.intValue)
            self.value = native.value?.intValue
        }

        /// The location of the road item, relative to the road.
        public struct Location: Hashable, Equatable, Sendable {
            private let rawValue: Int
            init(_ rawValue: Int) {
                self.rawValue = rawValue
            }

            /// :nodoc:
            public static let right = Location(0)
            /// :nodoc:
            public static let left = Location(1)
            /// :nodoc:
            public static let above = Location(2)
            /// :nodoc:
            public static let onSurface = Location(3)
            /// :nodoc:
            public static let aboveLane = Location(4)
        }

        /// The type of the road item.
        public struct Kind: Hashable, Equatable, Sendable {
            private let rawValue: Int
            private init(_ rawValue: Int) {
                self.rawValue = rawValue
            }

            /// :nodoc:
            public static let dangerSign = Kind(0)
            /// :nodoc:
            public static let passLeftOrRightSideSign = Kind(1)
            /// :nodoc:
            public static let passLeftSideSign = Kind(2)
            /// :nodoc:
            public static let passRightSideSign = Kind(3)
            /// :nodoc:
            public static let domesticAnimalsCrossingSign = Kind(4)
            /// :nodoc:
            public static let wildAnimalsCrossingSign = Kind(5)
            /// :nodoc:
            public static let roadWorksSign = Kind(6)
            /// :nodoc:
            public static let residentialAreaSign = Kind(7)
            /// :nodoc:
            public static let endOfResidentialAreaSign = Kind(8)
            /// :nodoc:
            public static let rightBendSign = Kind(9)
            /// :nodoc:
            public static let leftBendSign = Kind(10)
            /// :nodoc:
            public static let doubleBendRightFirstSign = Kind(11)
            /// :nodoc:
            public static let doubleBendLeftFirstSign = Kind(12)
            /// :nodoc:
            public static let curvyRoadSign = Kind(13)
            /// :nodoc:
            public static let overtakingByGoodsVehiclesProhibitedSign = Kind(14)
            /// :nodoc:
            public static let endOfProhibitionOnOvertakingForGoodsVehiclesSign = Kind(15)
            /// :nodoc:
            public static let dangerousIntersectionSign = Kind(16)
            /// :nodoc:
            public static let tunnelSign = Kind(17)
            /// :nodoc:
            public static let ferryTerminalSign = Kind(18)
            /// :nodoc:
            public static let narrowBridgeSign = Kind(19)
            /// :nodoc:
            public static let humpbackBridgeBridgeSign = Kind(20)
            /// :nodoc:
            public static let riverBankSign = Kind(21)
            /// :nodoc:
            public static let riverBankLeftSign = Kind(22)
            /// :nodoc:
            public static let yieldSign = Kind(23)
            /// :nodoc:
            public static let stopSign = Kind(24)
            /// :nodoc:
            public static let priorityRoadSign = Kind(25)
            /// :nodoc:
            public static let intersectionSign = Kind(26)
            /// :nodoc:
            public static let intersectionWithMinorRoadSign = Kind(27)
            /// :nodoc:
            public static let intersectionWithPriorityToTheRightSign = Kind(28)
            /// :nodoc:
            public static let directionToTheRightSign = Kind(29)
            /// :nodoc:
            public static let directionToTheLeftSign = Kind(30)
            /// :nodoc:
            public static let carriagewayNarrowsSign = Kind(31)
            /// :nodoc:
            public static let carriagewayNarrowsRightSign = Kind(32)
            /// :nodoc:
            public static let carriagewayNarrowsLeftSign = Kind(33)
            /// :nodoc:
            public static let laneMergeLeftSign = Kind(34)
            /// :nodoc:
            public static let laneMergeRightSign = Kind(35)
            /// :nodoc:
            public static let laneMergeCenterSign = Kind(36)
            /// :nodoc:
            public static let overtakingProhibitedSign = Kind(37)
            /// :nodoc:
            public static let endOfProhibitionOnOvertakingSign = Kind(38)
            /// :nodoc:
            public static let protectiveOvertakingSign = Kind(39)
            /// :nodoc:
            public static let pedestriansSign = Kind(40)
            /// :nodoc:
            public static let pedestrianCrossingSign = Kind(41)
            /// :nodoc:
            public static let childrenSign = Kind(42)
            /// :nodoc:
            public static let schoolZoneSign = Kind(43)
            /// :nodoc:
            public static let cyclistsSign = Kind(44)
            /// :nodoc:
            public static let twoWayTrafficSign = Kind(45)
            /// :nodoc:
            public static let railwayCrossingWithGatesSign = Kind(46)
            /// :nodoc:
            public static let railwayCrossingWithoutGatesSign = Kind(47)
            /// :nodoc:
            public static let railwayCrossingSign = Kind(48)
            /// :nodoc:
            public static let tramwaySign = Kind(49)
            /// :nodoc:
            public static let fallingRocksSign = Kind(50)
            /// :nodoc:
            public static let fallingRocksLeftSign = Kind(51)
            /// :nodoc:
            public static let fallingRocksRightSign = Kind(52)
            /// :nodoc:
            public static let steepDropLeftSign = Kind(53)
            /// :nodoc:
            public static let steepDropRightSign = Kind(54)
            /// :nodoc:
            public static let variableSignMechanicElementsSign = Kind(55)
            /// :nodoc:
            public static let slipperyRoadSign = Kind(56)
            /// :nodoc:
            public static let steepAscentSign = Kind(57)
            /// :nodoc:
            public static let steepDescentSign = Kind(58)
            /// :nodoc:
            public static let unevenRoadSign = Kind(59)
            /// :nodoc:
            public static let humpSign = Kind(60)
            /// :nodoc:
            public static let dipSign = Kind(61)
            /// :nodoc:
            public static let roadFloodsSign = Kind(62)
            /// :nodoc:
            public static let icyRoadSign = Kind(63)
            /// :nodoc:
            public static let sideWindsSign = Kind(64)
            /// :nodoc:
            public static let trafficCongestionSign = Kind(65)
            /// :nodoc:
            public static let highAccidentAreaSign = Kind(66)
            /// :nodoc:
            public static let variableSignLightElementsSign = Kind(66)
            /// :nodoc:
            public static let priorityOverOncomingTrafficSign = Kind(67)
            /// :nodoc:
            public static let priorityForOncomingTrafficSign = Kind(68)
            /// :nodoc:
            public static let speedLimitSign = Kind(69)
            /// :nodoc:
            public static let tollBooth = Kind(70)
            /// :nodoc:
            public static let roadCamSpeedIntervalEnd = Kind(71)
            /// :nodoc:
            public static let roadCamSpeedIntervalStart = Kind(72)
            /// :nodoc:
            public static let roadCamSpeedInterval = Kind(73)
            /// :nodoc:
            public static let roadCamLaneNonMotorized = Kind(74)
            /// :nodoc:
            public static let roadCamLaneEmergency = Kind(75)
            /// :nodoc:
            public static let roadCamLaneBus = Kind(76)
            /// :nodoc:
            public static let roadCamViolation = Kind(77)
            /// :nodoc:
            public static let roadCamRedLight = Kind(78)
            /// :nodoc:
            public static let roadCamSurveillance = Kind(79)
            /// :nodoc:
            public static let roadCamSpeedCurrentSpeed = Kind(80)
            /// :nodoc:
            public static let railroadCrossing = Kind(81)
            /// :nodoc:
            public static let zebra = Kind(82)
            /// :nodoc:
            public static let speedBump = Kind(83)
            /// :nodoc:
            public static let trafficLight = Kind(84)
            /// :nodoc:
            public static let undefined = Kind(-1)

            init(_ native: MapboxNavigationNative_Private.RoadItemType) {
                switch native {
                case .dangerSign:
                    self = .dangerSign
                case .passLeftOrRightSideSign:
                    self = .passLeftOrRightSideSign
                case .passLeftSideSign:
                    self = .passLeftSideSign
                case .passRightSideSign:
                    self = .passRightSideSign
                case .domesticAnimalsCrossingSign:
                    self = .domesticAnimalsCrossingSign
                case .wildAnimalsCrossingSign:
                    self = .wildAnimalsCrossingSign
                case .roadWorksSign:
                    self = .roadWorksSign
                case .residentialAreaSign:
                    self = .residentialAreaSign
                case .endOfResidentialAreaSign:
                    self = .endOfResidentialAreaSign
                case .rightBendSign:
                    self = .rightBendSign
                case .leftBendSign:
                    self = .leftBendSign
                case .doubleBendRightFirstSign:
                    self = .doubleBendRightFirstSign
                case .doubleBendLeftFirstSign:
                    self = .doubleBendLeftFirstSign
                case .curvyRoadSign:
                    self = .curvyRoadSign
                case .overtakingByGoodsVehiclesProhibitedSign:
                    self = .overtakingByGoodsVehiclesProhibitedSign
                case .endOfProhibitionOnOvertakingForGoodsVehiclesSign:
                    self = .endOfProhibitionOnOvertakingForGoodsVehiclesSign
                case .dangerousIntersectionSign:
                    self = .dangerousIntersectionSign
                case .tunnelSign:
                    self = .tunnelSign
                case .ferryTerminalSign:
                    self = .ferryTerminalSign
                case .narrowBridgeSign:
                    self = .narrowBridgeSign
                case .humpbackBridgeBridgeSign:
                    self = .humpbackBridgeBridgeSign
                case .riverBankSign:
                    self = .riverBankSign
                case .riverBankLeftSign:
                    self = .riverBankLeftSign
                case .yieldSign:
                    self = .yieldSign
                case .stopSign:
                    self = .stopSign
                case .priorityRoadSign:
                    self = .priorityRoadSign
                case .intersectionSign:
                    self = .intersectionSign
                case .intersectionWithMinorRoadSign:
                    self = .intersectionWithMinorRoadSign
                case .intersectionWithPriorityToTheRightSign:
                    self = .intersectionWithPriorityToTheRightSign
                case .directionToTheRightSign:
                    self = .directionToTheRightSign
                case .directionToTheLeftSign:
                    self = .directionToTheLeftSign
                case .carriagewayNarrowsSign:
                    self = .carriagewayNarrowsSign
                case .carriagewayNarrowsRightSign:
                    self = .carriagewayNarrowsRightSign
                case .carriagewayNarrowsLeftSign:
                    self = .carriagewayNarrowsLeftSign
                case .laneMergeLeftSign:
                    self = .laneMergeLeftSign
                case .laneMergeRightSign:
                    self = .laneMergeRightSign
                case .laneMergeCenterSign:
                    self = .laneMergeCenterSign
                case .overtakingProhibitedSign:
                    self = .overtakingProhibitedSign
                case .endOfProhibitionOnOvertakingSign:
                    self = .endOfProhibitionOnOvertakingSign
                case .protectiveOvertakingSign:
                    self = .protectiveOvertakingSign
                case .pedestriansSign:
                    self = .pedestriansSign
                case .pedestrianCrossingSign:
                    self = .pedestrianCrossingSign
                case .childrenSign:
                    self = .childrenSign
                case .schoolZoneSign:
                    self = .schoolZoneSign
                case .cyclistsSign:
                    self = .cyclistsSign
                case .twoWayTrafficSign:
                    self = .twoWayTrafficSign
                case .railwayCrossingWithGatesSign:
                    self = .railwayCrossingWithGatesSign
                case .railwayCrossingWithoutGatesSign:
                    self = .railwayCrossingWithoutGatesSign
                case .railwayCrossingSign:
                    self = .railwayCrossingSign
                case .tramwaySign:
                    self = .tramwaySign
                case .fallingRocksSign:
                    self = .fallingRocksSign
                case .fallingRocksLeftSign:
                    self = .fallingRocksLeftSign
                case .fallingRocksRightSign:
                    self = .fallingRocksRightSign
                case .steepDropLeftSign:
                    self = .steepDropLeftSign
                case .steepDropRightSign:
                    self = .steepDropRightSign
                case .variableSignMechanicElementsSign:
                    self = .variableSignMechanicElementsSign
                case .slipperyRoadSign:
                    self = .slipperyRoadSign
                case .steepAscentSign:
                    self = .steepAscentSign
                case .steepDescentSign:
                    self = .steepDescentSign
                case .unevenRoadSign:
                    self = .unevenRoadSign
                case .humpSign:
                    self = .humpSign
                case .dipSign:
                    self = .dipSign
                case .roadFloodsSign:
                    self = .roadFloodsSign
                case .icyRoadSign:
                    self = .icyRoadSign
                case .sideWindsSign:
                    self = .sideWindsSign
                case .trafficCongestionSign:
                    self = .trafficCongestionSign
                case .highAccidentAreaSign:
                    self = .highAccidentAreaSign
                case .variableSignLightElementsSign:
                    self = .variableSignLightElementsSign
                case .priorityOverOncomingTrafficSign:
                    self = .priorityOverOncomingTrafficSign
                case .priorityForOncomingTrafficSign:
                    self = .priorityForOncomingTrafficSign
                case .speedLimitSign:
                    self = .speedLimitSign
                case .tollBooth:
                    self = .tollBooth
                case .roadCamSpeedIntervalEnd:
                    self = .roadCamSpeedIntervalEnd
                case .roadCamSpeedIntervalStart:
                    self = .roadCamSpeedIntervalStart
                case .roadCamSpeedInterval:
                    self = .roadCamSpeedInterval
                case .roadCamLaneNonMotorized:
                    self = .roadCamLaneNonMotorized
                case .roadCamLaneEmergency:
                    self = .roadCamLaneEmergency
                case .roadCamLaneBus:
                    self = .roadCamLaneBus
                case .roadCamViolation:
                    self = .roadCamViolation
                case .roadCamRedLight:
                    self = .roadCamRedLight
                case .roadCamSurveillance:
                    self = .roadCamSurveillance
                case .roadCamSpeedCurrentSpeed:
                    self = .roadCamSpeedCurrentSpeed
                case .railroadCrossing:
                    self = .railroadCrossing
                case .zebra:
                    self = .zebra
                case .speedBump:
                    self = .speedBump
                case .trafficLight:
                    self = .trafficLight
                @unknown default:
                    self = .undefined
                }
            }
        }
    }
}
