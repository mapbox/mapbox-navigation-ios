import Foundation
@testable import MapboxCoreNavigation

public final class BillingServiceMock: BillingService {
    public var onBeginBillingSession: ((_ sessionType: BillingHandler.SessionType,
                                 _ callback: @escaping (BillingServiceError) -> Void) -> Void)?
    public var onGetSKUTokenIfValid: (() -> String)?
    public var onStopBillingSession: (() -> Void)?
    public var onTriggerBillingEvent: ((_ onError: @escaping (BillingServiceError) -> Void) -> Void)?
    public var onPauseBillingSession: (() -> Void)?
    public var onResumeBillingSession: ((_ onError: @escaping (BillingServiceError) -> Void) -> Void)?

    public init() {}

    public func getSKUTokenIfValid() -> String {
        onGetSKUTokenIfValid?() ?? ""
    }

    public func stopBillingSession() {
        onStopBillingSession?()
    }

    public func triggerBillingEvent(onError: @escaping (BillingServiceError) -> Void) {
        onTriggerBillingEvent?(onError)
    }

    public func beginBillingSession(sessionType: BillingHandler.SessionType, onError: @escaping (BillingServiceError) -> Void) {
        onBeginBillingSession?(sessionType, onError)
    }

    public func pauseBillingSession() {
        onPauseBillingSession?()
    }

    public func resumeBillingSession(onError: @escaping (BillingServiceError) -> Void) {
        onResumeBillingSession?(onError)
    }
}
