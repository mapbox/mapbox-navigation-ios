import Foundation

@dynamicMemberLookup
public struct UncheckedSendable<Value>: @unchecked Sendable {
    public var value: Value

    public init(_ value: Value) {
        self.value = value
    }

    public subscript<Subject>(dynamicMember keyPath: KeyPath<Value, Subject>) -> Subject {
        self.value[keyPath: keyPath]
    }
}
