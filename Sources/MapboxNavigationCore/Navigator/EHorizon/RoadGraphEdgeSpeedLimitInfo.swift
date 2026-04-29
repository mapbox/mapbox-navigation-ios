import MapboxNavigationNative_Private

extension RoadGraph.Edge {
    /// Speed limit information for a specific ``RoadGraph/Edge``.
    public struct SpeedLimitInfo: Hashable, Sendable {
        /// Speed limit value in specified units.
        public let speedLimit: Measurement<UnitSpeed>
        /// Type of Speed Limit from its source perspective: implicit or explicit.
        public let kind: Kind
        /// Speed limit restriction information.
        public let restriction: Restriction

        init(speedLimit: Measurement<UnitSpeed>, kind: Kind, restriction: Restriction) {
            self.speedLimit = speedLimit
            self.kind = kind
            self.restriction = restriction
        }

        init(_ native: MapboxNavigationNative_Private.SpeedLimitInfo) {
            self.speedLimit = .init(
                value: Double(native.value),
                unit: native.unit == .kilometresPerHour ? .kilometersPerHour : .milesPerHour
            )
            self.kind = .init(native.type)
            self.restriction = .init(native.restriction)
        }

        /// Speed limit type.
        /// Provides a context about where this speed limit comes from.
        public struct Kind: Hashable, Sendable {
            private let rawValue: Int
            private init(_ rawValue: Int) {
                self.rawValue = rawValue
            }

            /// Means no sign, limit is set by regulations for urban / rural / living street.
            public static let implicit = Kind(0)
            /// Edge starts with a speed limit sign.
            public static let explicit = Kind(1)
            /// No exact information on presence of sign.
            public static let unknown = Kind(2)
            /// Edge does not start the way, no sign on the edge. Speed limit time is the same of on previous edge.
            public static let prolonged = Kind(3)
            /// Unrecognized value.
            public static let undefined = Kind(-1)

            init(_ native: MapboxNavigationNative_Private.SpeedLimitType) {
                switch native {
                case .implicit:
                    self = .implicit
                case .explicit:
                    self = .explicit
                case .unknown:
                    self = .unknown
                case .prolonged:
                    self = .prolonged
                @unknown default:
                    self = .undefined
                }
            }
        }

        /// Provides additional details for the speed limit.
        public struct Restriction: Hashable, Sendable {
            /// Weather conditions where the speed limit is applied.
            /// Empty means all.
            public let weather: [Weather]
            /// OSM openning_hours format.
            ///
            /// See https://wiki.openstreetmap.org/wiki/Key:opening_hours for more details and examples.
            public let timeCondition: String
            /// A list of types of vehicles for that the speed limit is included.
            /// Empty means all
            public let vehicleTypes: [VehicleType]
            /// Lane numbers where the speed limit is valid.
            /// Empty array means all lanes.
            public let lanes: [Int]

            init(weather: [Weather], timeCondition: String, vehicleTypes: [VehicleType], lanes: [Int]) {
                self.weather = weather
                self.timeCondition = timeCondition
                self.vehicleTypes = vehicleTypes
                self.lanes = lanes
            }

            init(_ native: MapboxNavigationNative_Private.SpeedLimitRestriction) {
                self.weather = native.weather.map { Weather($0.intValue) }
                self.timeCondition = native.dateTimeCondition
                self.vehicleTypes = native.vehicleTypes.map { VehicleType($0.intValue) }
                self.lanes = native.lanes.map(\.intValue)
            }
        }
    }
}

extension RoadGraph.Edge {
    /// Mether condition, used as a context for specific restrictions.
    public struct Weather: Hashable, Sendable {
        /// :nodoc:
        public let rawValue: Int
        init(_ rawValue: Int) {
            self.rawValue = rawValue
        }

        /// :nodoc:
        public static let rain = Weather(0)
        /// :nodoc:
        public static let snow = Weather(1)
        /// :nodoc:
        public static let fog = Weather(2)
        /// :nodoc:
        public static let wetRoad = Weather(3)
    }

    /// Vehicle type condition, used as a context for specific restrictions.
    public struct VehicleType: Hashable, Sendable {
        /// :nodoc:
        public let rawValue: Int
        init(_ rawValue: Int) {
            self.rawValue = rawValue
        }

        /// :nodoc:
        public static let car = VehicleType(0)
        /// :nodoc:
        public static let truck = VehicleType(1)
        /// :nodoc:
        public static let bus = VehicleType(2)
        /// :nodoc:
        public static let trailer = VehicleType(3)
        /// :nodoc:
        public static let motorcycle = VehicleType(4)
    }
}
