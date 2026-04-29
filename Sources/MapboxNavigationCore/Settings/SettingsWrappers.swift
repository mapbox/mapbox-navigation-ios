import Foundation

public enum ApprovalMode<Context>: Equatable, Sendable {
    case automatically
    case manually
}

public enum ApprovalModeAsync<Context: Sendable>: Equatable, Sendable {
    public static func == (lhs: ApprovalModeAsync<Context>, rhs: ApprovalModeAsync<Context>) -> Bool {
        switch (lhs, rhs) {
        case (.automatically, .automatically),
             (.manually(_), .manually(_)):
            return true
        default:
            return false
        }
    }

    public typealias ApprovalCheck = @Sendable (Context) async -> Bool

    case automatically
    case manually(ApprovalCheck)
}

public struct EquatableClosure<Input, Output>: Equatable {
    public static func == (lhs: EquatableClosure<Input, Output>, rhs: EquatableClosure<Input, Output>) -> Bool {
        return (lhs.closure != nil) == (rhs.closure != nil)
    }

    public typealias Closure = (Input) -> Output
    private var closure: Closure?

    func callAsFunction(_ input: Input) -> Output? {
        return closure?(input)
    }

    public init(_ closure: Closure? = nil) {
        self.closure = closure
    }
}
