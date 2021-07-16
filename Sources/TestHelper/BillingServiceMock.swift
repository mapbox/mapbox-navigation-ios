import Foundation
@testable import MapboxCoreNavigation

public final class BillingServiceMock: BillingService {
    public var onBeginBillingSession: ((_ sessionType: BillingHandler.SessionType,
                                        _ callback: @escaping (BillingServiceError) -> Void) -> Void)?
    public var onGetSKUTokenIfValid: ((_ sessionType: BillingHandler.SessionType) -> String)?
    public var onStopBillingSession: ((_ sessionType: BillingHandler.SessionType) -> Void)?
    public var onTriggerBillingEvent: ((_ onError: @escaping (BillingServiceError) -> Void) -> Void)?
    public var onPauseBillingSession: ((_ sessionType: BillingHandler.SessionType) -> Void)?
    public var onResumeBillingSession: ((_ sessionType: BillingHandler.SessionType,
                                         _ onError: @escaping (BillingServiceError) -> Void) -> Void)?

    public init() {}

    public func getSKUTokenIfValid(for sessionType: BillingHandler.SessionType) -> String {
        onGetSKUTokenIfValid?(sessionType) ?? ""
    }

    public func stopBillingSession(for sessionType: BillingHandler.SessionType) {
        onStopBillingSession?(sessionType)
    }

    public func triggerBillingEvent(onError: @escaping (BillingServiceError) -> Void) {
        onTriggerBillingEvent?(onError)
    }

    public func beginBillingSession(for sessionType: BillingHandler.SessionType,
                                    onError: @escaping (BillingServiceError) -> Void) {
        onBeginBillingSession?(sessionType, onError)
    }

    public func pauseBillingSession(for sessionType: BillingHandler.SessionType) {
        onPauseBillingSession?(sessionType)
    }

    public func resumeBillingSession(for sessionType: BillingHandler.SessionType,
                                     onError: @escaping (BillingServiceError) -> Void) {
        onResumeBillingSession?(sessionType, onError)
    }
}
