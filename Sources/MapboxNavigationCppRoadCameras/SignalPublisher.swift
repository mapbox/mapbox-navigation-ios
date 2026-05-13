import Combine
import Foundation
import MapboxCommon

func publisher<T>(
    register: @escaping (@escaping (T) -> Void) -> MapboxCommon.Cancelable
) -> AnyPublisher<T, Never> {
    let subject = PassthroughSubject<T, Never>()
    let cancelable = register { value in
        subject.send(value)
    }
    return subject
        .handleEvents(receiveCancel: { _ = cancelable })
        .eraseToAnyPublisher()
}

func publisher(
    register: @escaping (@escaping () -> Void) -> MapboxCommon.Cancelable
) -> AnyPublisher<Void, Never> {
    let subject = PassthroughSubject<Void, Never>()
    let cancelable = register {
        subject.send(())
    }
    return subject
        .handleEvents(receiveCancel: { _ = cancelable })
        .eraseToAnyPublisher()
}
