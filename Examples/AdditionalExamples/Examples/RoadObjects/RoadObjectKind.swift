import MapboxDirections
import MapboxNavigationCore

extension RoadObject.Kind {
    var displayDescription: String {
        switch self {
        case .incident(let incident?):
            return incident.alertDescription
        case .tunnel(let alert?):
            if let alertName = alert.name {
                return "Tunnel \(alertName)"
            } else {
                return "A tunnel"
            }
        case .borderCrossing(let alert?):
            return "Crossing border from \(alert.from) to \(alert.to)"
        case .serviceArea(let alert?):
            switch alert.type {
            case .restArea:
                return "Rest area"
            case .serviceArea:
                return "Service area"
            }
        case .tollCollection(let alert?):
            switch alert.type {
            case .booth:
                return "Toll booth"
            case .gantry:
                return "Toll gantry"
            }
        case .bridge:
            return "Bridge"
        case .restrictedArea:
            return "Restricted area"
        case .railroadCrossing:
            return "Railroad crossing"
        case .userDefined:
            return "Custom road object"
        default:
            return "-"
        }
    }
}

extension MapboxDirections.Incident {
    fileprivate var alertDescription: String {
        guard let kind else { return description }

        return switch (impact, lanesBlocked) {
        case (let impact?, let lanesBlocked?):
            "A \(impact) \(kind) ahead blocking \(lanesBlocked)"
        case (let impact?, nil):
            "A \(impact) \(kind) ahead"
        case (nil, let lanesBlocked?):
            "A \(kind) ahead blocking \(lanesBlocked)"
        case (nil, nil):
            "A \(kind) ahead"
        }
    }
}

extension DistancedRoadObject {
    var distanceString: String {
        switch self {
        case .point(_, _, let distance),
             .gantry(_, _, let distance):
            "in \(Int64(distance)) m"
        case .polygon(_, _, let distanceToNearestEntry, let distanceToNearestExit, let isInside),
             .subgraph(_, _, let distanceToNearestEntry, let distanceToNearestExit, let isInside):
            isInside ? "exit in \(Int64(distanceToNearestExit ?? 0)) m" :
                "entry in \(Int64(distanceToNearestEntry ?? 0)) m"
        case .line(_, _, let distanceToEntry, let distanceToExit, _, _, _):
            distanceToEntry != 0 ? "entry in \(Int64(distanceToEntry)) m" :
                "exit in \(Int64(distanceToExit)) m"
        }
    }
}
