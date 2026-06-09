import CoreLocation
import Foundation
import MapboxDirections
import Turf

extension Incident {
    static func mock(
        identifier: String = "mock-incident",
        type: Kind = .accident,
        description: String = "",
        creationDate: Date = Date(),
        startDate: Date = Date(),
        endDate: Date = Date(),
        impact: Impact? = nil,
        subtype: String? = nil,
        subtypeDescription: String? = nil,
        alertCodes: Set<Int> = [],
        lanesBlocked: BlockedLanes? = nil,
        shapeIndexRange: Range<Int> = 0..<1
    ) -> Self {
        Incident(
            identifier: identifier,
            type: type,
            description: description,
            creationDate: creationDate,
            startDate: startDate,
            endDate: endDate,
            impact: impact,
            subtype: subtype,
            subtypeDescription: subtypeDescription,
            alertCodes: alertCodes,
            lanesBlocked: lanesBlocked,
            shapeIndexRange: shapeIndexRange
        )
    }
}
