import MapboxNavigationNative_Private

extension RoadGraph.Edge {
    /// Hints the logical type of a road on a specific segment.
    public struct FormOfWay: Hashable, Equatable, Sendable {
        private let rawValue: Int
        init(_ rawValue: Int) {
            self.rawValue = rawValue
        }

        /// Unknown form of way.
        public static let unknown = FormOfWay(0)
        /// Freeway or Controlled Access road that is not a slip road/ramp
        /// (“Controlled Access” means that the road looks like a freeway (grade
        /// separated crossings, physical center divider, motor vehicle only), not
        /// necessarily that the road is legally defined as a freeway. Note that
        /// different map makers may use a different wording for this signal.).
        public static let freeway = FormOfWay(1)
        /// Multiple Carriageway or Multiply Digitized Road.
        public static let multipleCarriageway = FormOfWay(2)
        /// Single Carriageway (default).
        public static let singleCarriageway = FormOfWay(3)
        /// Roundabout Circle.
        public static let roundaboutCircle = FormOfWay(4)
        /// Traffic Square/Special Traffic Figure.
        public static let trafficSquare = FormOfWay(5)
        /// Slip road.
        public static let slipRoad = FormOfWay(6)
        /// Reserved value.
        public static let reserved = FormOfWay(7)
        /// Parallel Road (as special type of a slip road/ramp).
        public static let parallelRoad = FormOfWay(8)
        /// Slip Road/Ramp on a Freeway or Controlled Access road.
        public static let rampOnFreeway = FormOfWay(9)
        /// Slip Road/Ramp (not on a Freeway or Controlled Access road).
        public static let ramp = FormOfWay(10)
        /// Service Road or Frontage Road.
        public static let serviceRoad = FormOfWay(11)
        /// Entrance to or exit of a Car Park.
        public static let carParkEntrance = FormOfWay(12)
        /// Entrance to or exit to Service.
        public static let serviceEntrance = FormOfWay(13)
        /// Pedestrian Zone.
        public static let pedestrianZone = FormOfWay(14)
        /// Information not available.
        public static let NA = FormOfWay(15)
    }
}
