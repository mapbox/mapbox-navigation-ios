import Foundation

extension NavigationHistoryEvents {
    struct DriveEnds: Event {
        enum DriveEndType: String, Encodable {
            case applicationClosed = "application_closed"
            case vehicleParked = "vehicle_parked"
            case arrived
            case canceledManually = "canceled_manually"
        }

        struct Payload: Encodable {
            var type: DriveEndType
            var realDuration: Int
        }

        let eventType = "drive_ends"
        var payload: Payload
    }
}
