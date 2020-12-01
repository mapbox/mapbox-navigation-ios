
import Foundation
import MapboxNavigationNative
import MapboxDirections

extension Incident {
    init(_ incidentInfo: RouteAlertIncidentInfo) {
        self.init(identifier: incidentInfo.id,
                  type: "type",
                  description: incidentInfo.description ?? "",
                  creationTime: incidentInfo.creationTime?.ISO8601 ?? "",
                  startTime: incidentInfo.startTime?.ISO8601 ?? "",
                  endTime: incidentInfo.endTime?.ISO8601 ?? "",
                  impact: incidentInfo.impact ?? "",
                  subtype: incidentInfo.subType,
                  subtypeDescription: incidentInfo.subTypeDescription,
                  alertCodes: incidentInfo.alertcCodes.map { $0.intValue },
                  lanesBlocked: incidentInfo.lanesBlocked.map { Int($0) ?? -1 },
                  geometryIndexStart: -1,
                  geometryIndexEnd: -1)
    }
}
