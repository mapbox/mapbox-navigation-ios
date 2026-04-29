import Combine

// NOTE: On `@unchecked Sendable`
// According to the sources I found `PassthroughSubject` and `CurrentValuePublisher` are thread safe, so we can mark
// this wrapper as thread-safe.
// https://forums.swift.org/t/thread-safety-for-combine-publishers/29491/13

@propertyWrapper
public final class EventPublisher<Event: Sendable>: @unchecked Sendable {
    private let subject: PassthroughSubject<Event, Never> = .init()

    public let wrappedValue: AnyPublisher<Event, Never>

    public func emit(_ event: Event) {
        subject.send(event)
    }

    public init() {
        self.wrappedValue = subject.eraseToAnyPublisher()
    }
}

extension EventPublisher where Event == Void {
    @inlinable
    public func emit() {
        emit(())
    }
}

/// `CurrentValueSubject` property wrapper, providing access to the publisher as `AnyPublisher` and it's current
/// `value`.
@propertyWrapper
public final class CurrentValuePublisher<Event: Sendable>: @unchecked Sendable {
    private let subject: CurrentValueSubject<Event, Never>

    public let wrappedValue: AnyPublisher<Event, Never>

    public var value: Event {
        subject.value
    }

    public func emit(_ event: Event) {
        subject.send(event)
    }

    public init(_ event: Event) {
        self.subject = .init(event)
        self.wrappedValue = subject.eraseToAnyPublisher()
    }
}
