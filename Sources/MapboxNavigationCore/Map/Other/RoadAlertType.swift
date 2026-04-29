import MapboxDirections

/// Represents different types of road alerts that can be displayed on a route.
/// Each alert type corresponds to a specific traffic condition or event that can affect the route.
public struct RoadAlertType: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// Indicates a road alert for an accident on the route.
    public static let accident = Self(rawValue: 1 << 0)

    /// Indicates a road alert for traffic congestion on the route.
    public static let congestion = Self(rawValue: 1 << 1)

    /// Indicates a road alert for construction along the route.
    public static let construction = Self(rawValue: 1 << 2)

    /// Indicates a road alert for a disabled vehicle on the route.
    public static let disabledVehicle = Self(rawValue: 1 << 3)

    /// Indicates a road alert for lane restrictions on the route.
    public static let laneRestriction = Self(rawValue: 1 << 4)

    /// Indicates a road alert related to mass transit on the route.
    public static let massTransit = Self(rawValue: 1 << 5)

    /// Indicates a miscellaneous road alert on the route.
    public static let miscellaneous = Self(rawValue: 1 << 6)

    /// Indicates a road alert for news impacting the route.
    public static let otherNews = Self(rawValue: 1 << 7)

    /// Indicates a road alert for a planned event impacting the route.
    public static let plannedEvent = Self(rawValue: 1 << 8)

    /// Indicates a road alert for a road closure on the route.
    public static let roadClosure = Self(rawValue: 1 << 9)

    /// Indicates a road alert for hazardous road conditions on the route.
    public static let roadHazard = Self(rawValue: 1 << 10)

    /// Indicates a road alert related to weather conditions affecting the route.
    public static let weather = Self(rawValue: 1 << 11)

    /// A collection that includes all possible road alert types.
    public static let all: Self = [
        .accident,
        .congestion,
        .construction,
        .disabledVehicle,
        .laneRestriction,
        .massTransit,
        .miscellaneous,
        .otherNews,
        .plannedEvent,
        .roadClosure,
        .roadHazard,
        .weather,
    ]
}

extension RoadAlertType {
    init?(roadObjectKind: RoadObject.Kind) {
        switch roadObjectKind {
        case .incident(let incident):
            guard let roadAlertType = incident?.kind.flatMap(RoadAlertType.init) else {
                return nil
            }
            self = roadAlertType

        case .tollCollection,
             .borderCrossing,
             .tunnel,
             .serviceArea,
             .restrictedArea,
             .bridge,
             .railroadCrossing,
             .userDefined,
             .ic,
             .jct,
             .undefined:
            return nil
        }
    }
}

extension RoadAlertType {
    private init?(incident: Incident.Kind) {
        switch incident {
        case .accident:
            self = .accident
        case .congestion:
            self = .congestion
        case .construction:
            self = .construction
        case .disabledVehicle:
            self = .disabledVehicle
        case .laneRestriction:
            self = .laneRestriction
        case .massTransit:
            self = .massTransit
        case .miscellaneous:
            self = .miscellaneous
        case .otherNews:
            self = .otherNews
        case .plannedEvent:
            self = .plannedEvent
        case .roadClosure:
            self = .roadClosure
        case .roadHazard:
            self = .roadHazard
        case .weather:
            self = .weather
        case .undefined:
            return nil
        }
    }
}
