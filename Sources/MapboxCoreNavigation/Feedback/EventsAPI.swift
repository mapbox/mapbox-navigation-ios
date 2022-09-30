import Foundation
@_implementationOnly import MapboxCommon_Private

protocol EventsAPI {
    func sendTurnstileEvent(sdkIdentifier: String, sdkVersion: String)
    func sendQueuedEvent(with attributes: [String: Any])
    func sendImmediateEvent(with attributes: [String: Any])
}

extension EventsService: EventsAPI {
    func sendTurnstileEvent(sdkIdentifier: String, sdkVersion: String) {
        let turnstileEvent = TurnstileEvent(skuId: .nav2SesMAU, sdkIdentifier: sdkIdentifier, sdkVersion: sdkVersion)
        sendTurnstileEvent(for: turnstileEvent)
    }

    func sendQueuedEvent(with attributes: [String : Any]) {
        sendEvent(for: Event(priority: .queued, attributes: attributes, deferredOptions: nil))
    }

    func sendImmediateEvent(with attributes: [String : Any]) {
        sendEvent(for: Event(priority: .immediate, attributes: attributes, deferredOptions: nil))
    }
}
