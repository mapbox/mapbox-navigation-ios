import Foundation
import XCTest
@testable import MapboxCoreNavigation

class EventsAPIMock: EventsAPI {
    private enum Keys {
        static let sdkIdentifierKey: String = "sdkIdentifier"
        static let sdkVersionKey: String = "sdkVersion"
    }

    private typealias MockEvent = [String: Any]

    private var queuedEvents = [MockEvent]()
    private var immediateEvents = [MockEvent]()

    func sendTurnstileEvent(sdkIdentifier: String, sdkVersion: String) {
        XCTAssertTrue(["mapbox-navigation-ios", "mapbox-navigation-ui-ios"].contains(sdkIdentifier))
        XCTAssertEqual(sdkVersion, Bundle.navigationSDKVersion)

        immediateEvents.append([
            EventKey.event.rawValue: EventType.turnstile.rawValue,
            Keys.sdkIdentifierKey: sdkIdentifier,
            Keys.sdkVersionKey: sdkVersion,
        ])
    }

    func sendQueuedEvent(with attributes: [String: Any]) {
        queuedEvents.append(attributes)
        assertSdkIdentifier(event: attributes)
    }

    func sendImmediateEvent(with attributes: [String: Any]) {
        immediateEvents.append(attributes)
        assertSdkIdentifier(event: attributes)
    }

    func reset() {
        queuedEvents.removeAll()
        immediateEvents.removeAll()
    }

    func hasQueuedEvent(with name: String) -> Bool {
        return hasEvent(in: queuedEvents, key: .event, value: name)
    }

    func hasImmediateEvent(with name: String) -> Bool {
        return hasEvent(in: immediateEvents, key: .event, value: name)
    }

    func immediateEventCount(with name: String) -> Int {
        return immediateEvents.filter { (event) in
            return event[EventKey.event.rawValue] as? String == name
        }.count
    }

    private func hasEvent<ValueType>(in array: [MockEvent], key: EventKey, value: ValueType) -> Bool where ValueType: Comparable {
        return array.contains { (event) -> Bool in
            guard
                let eventValue = event[key.rawValue] as? ValueType,
                eventValue == value
            else { return false }
            return true
        }
    }
    private func assertSdkIdentifier(event: MockEvent) {
        let eventsWithSdkInfoEvents = [
            EventType.arrive.rawValue,
            EventType.depart.rawValue,
            EventType.reroute.rawValue,
        ]
        if eventsWithSdkInfoEvents.contains(event[EventKey.event.rawValue] as? String ?? "") {
            XCTAssertTrue(
                ["mapbox-navigation-ios", "mapbox-navigation-ui-ios"]
                    .contains(event[Keys.sdkIdentifierKey] as? String?)
            )
            XCTAssertEqual(event[Keys.sdkVersionKey] as? String, Bundle.navigationSDKVersion)
        }
    }
}
