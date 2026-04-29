import Foundation

extension NavigationHistoryEvents {
    struct InitRoute: Event {
        struct Payload: Encodable {
            var requestIdentifier: String?
            var route: String
        }

        let eventType = "init_route"
        let payload: Payload

        init?(
            requestIdentifier: String?,
            route: Encodable
        ) {
            let encoder = JSONEncoder()
            guard let encodedData = try? encoder.encode(route),
                  let encodedRoute = String(data: encodedData, encoding: .utf8)
            else {
                assertionFailure("No route")
                return nil
            }
            self.payload = .init(
                requestIdentifier: requestIdentifier,
                route: encodedRoute
            )
        }
    }
}
