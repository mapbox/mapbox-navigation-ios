import Foundation

struct BillingHandlerProvider: Equatable {
    static func == (lhs: BillingHandlerProvider, rhs: BillingHandlerProvider) -> Bool {
        return lhs.object === rhs.object
    }

    private var object: BillingHandler
    func callAsFunction() -> BillingHandler {
        return object
    }

    init(_ object: BillingHandler) {
        self.object = object
    }
}
