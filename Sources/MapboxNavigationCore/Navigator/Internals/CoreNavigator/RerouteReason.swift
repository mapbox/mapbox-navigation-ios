import Foundation

struct RerouteReason: Equatable, Sendable {
    let rawValue: String

    static let deviation: Self = .init(rawValue: "deviation")
    static let closure: Self = .init(rawValue: "closure")
    static let insufficientCharge: Self = .init(rawValue: "insufficient_charge")
    static let parametersChange: Self = .init(rawValue: "parameters_change")
    static let routeInvalidated: Self = .init(rawValue: "route_invalidated")
}

extension RerouteReason {
    init?(routeRequest: String) {
        guard
            let components = URLComponents(string: routeRequest),
            let queryItems = components.queryItems,
            let reasonValue = queryItems.first(where: { $0.name == "reason" })?.value
        else {
            return nil
        }

        switch reasonValue {
        case RerouteReason.deviation.rawValue:
            self = .deviation
        case RerouteReason.closure.rawValue:
            self = .closure
        case RerouteReason.insufficientCharge.rawValue:
            self = .insufficientCharge
        case RerouteReason.parametersChange.rawValue:
            self = .parametersChange
        case RerouteReason.routeInvalidated.rawValue:
            self = .routeInvalidated
        default:
            return nil
        }
    }
}
