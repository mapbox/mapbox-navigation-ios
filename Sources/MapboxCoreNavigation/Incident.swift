import Foundation
import MapboxNavigationNative
import MapboxDirections

extension Incident {
    init(_ incidentInfo: IncidentInfo) {
        let incidentType: Incident.Kind
        switch incidentInfo.type {
        case .accident:
            incidentType = .accident
        case .congestion:
            incidentType = .congestion
        case .construction:
            incidentType = .construction
        case .disabledVehicle:
            incidentType = .disabledVehicle
        case .laneRestriction:
            incidentType = .laneRestriction
        case .massTransit:
            incidentType = .massTransit
        case .miscellaneous:
            incidentType = .miscellaneous
        case .otherNews:
            incidentType = .otherNews
        case .plannedEvent:
            incidentType = .plannedEvent
        case .roadClosure:
            incidentType = .roadClosure
        case .roadHazard:
            incidentType = .roadHazard
        case .weather:
            incidentType = .weather
        @unknown default:
            fatalError("Unknown IncidentInfo type.")
        }

        self.init(identifier: incidentInfo.id,
                  type: incidentType,
                  description: incidentInfo.description ?? "",
                  creationDate: incidentInfo.creationTime ?? Date.distantPast,
                  startDate: incidentInfo.startTime ?? Date.distantPast,
                  endDate: incidentInfo.endTime ?? Date.distantPast,
                  impact: .init(incidentInfo.impact),
                  subtype: incidentInfo.subType,
                  subtypeDescription: incidentInfo.subTypeDescription,
                  alertCodes: Set(incidentInfo.alertcCodes.map { $0.intValue }),
                  lanesBlocked: BlockedLanes(descriptions: incidentInfo.lanesBlocked),
                  shapeIndexRange: -1 ..< -1,
                  countryCodeAlpha3: incidentInfo.iso_3166_1_alpha3,
                  countryCode: incidentInfo.iso_3166_1_alpha2,
                  roadIsClosed: incidentInfo.isRoadClosed,
                  longDescription: incidentInfo.longDescription,
                  numberOfBlockedLanes: incidentInfo.numLanesBlocked?.intValue,
                  congestionLevel: incidentInfo.congestion?.value?.intValue,
                  affectedRoadNames: incidentInfo.affectedRoadNames,
                  trafficCodes: .init(incidentInfo.trafficCodes)
        )
    }
}

extension Incident.Impact {
    init(_ incidentImpact: IncidentImpact) {
        switch incidentImpact {
        case .unknown:
            self = .unknown
        case .critical:
            self = .critical
        case .major:
            self = .major
        case .minor:
            self = .minor
        case .low:
            self = .low
        @unknown default:
            fatalError("Unknown IncidentImpact value.")
        }
    }
}

extension Incident.TrafficCodes {
    init?(_ data: [String: NSNumber]) {
        let codableData = Dictionary(uniqueKeysWithValues: data.map { ($0.key, $0.value.uint32Value) })
        guard let json = try? JSONEncoder().encode(codableData),
              let decoded = try? JSONDecoder().decode(Incident.TrafficCodes.self, from: json) else {
            return nil
        }
        self = decoded
    }
}
