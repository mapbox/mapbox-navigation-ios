import Foundation

struct CustomRoutingProvider: Equatable {
    static func == (lhs: CustomRoutingProvider, rhs: CustomRoutingProvider) -> Bool {
        lhs.object === rhs.object
    }

    private var object: RoutingProvider & AnyObject
    func callAsFunction() -> RoutingProvider {
        return object
    }

    init(_ object: RoutingProvider & AnyObject) {
        self.object = object
    }
}
