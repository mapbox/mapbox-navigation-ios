import Foundation
@_implementationOnly import MapboxCommon_Private

protocol BillingService {
    func getSKUTokenIfValid() -> String
    func beginBillingSession(sessionType: BillingHandler.SessionType,
                             onError: @escaping (Error) -> Void)
    func pauseBillingSession()
    func resumeBillingSession(onError: @escaping (Error) -> Void)
    func stopBillingSession()
    func triggerBillingEvent(onError: @escaping (Error) -> Void)
}

private final class ProductionBillingService: BillingService {
    func getSKUTokenIfValid() -> String {
        TokenGenerator.getSKUToken(for: .navigationMAUS) // temporary use sku token. Replace with session token above
    }

    func beginBillingSession(sessionType: BillingHandler.SessionType,
                             onError: @escaping (Error) -> Void) {
        print(">>>> Beging Billing Session: \(sessionType)")
    }
    func pauseBillingSession() {
        print(">>>> Pause Billing Session")
    }

    func resumeBillingSession(onError: @escaping (Error) -> Void) {
        print(">>>> Resume Billing Session")
    }
    func stopBillingSession() {
        print(">>>> Stop Billing Session")
    }

    func triggerBillingEvent(onError: @escaping (Error) -> Void) {
        print(">>>> MAU Event")
    }
}

final class BillingHandler {
    enum SessionState: Equatable {
        case stopped
        case paused
        case running
    }

    struct SessionType: Equatable {
        let maxSessionInterval: TimeInterval
        static var freeDrive: SessionType { .init(maxSessionInterval: 3600 /*2h*/) }
        static var activeGuidance: SessionType { .init(maxSessionInterval: 43200 /*12h*/) }
    }

    static let shared: BillingHandler = .init(service: ProductionBillingService())

    private let billingService: BillingService

    private let lock: NSLock = .init()
    private var _startedSessionCount: Int = 0
    private var _sessionState: SessionState
    private var _sessionType: SessionType

    var sessionState: SessionState {
        lock.lock(); defer {
            lock.unlock()
        }
        return _sessionState
    }
    
    init(service: BillingService) {
        self.billingService = service
        self._sessionState = .stopped
        self._sessionType = .freeDrive
    }
    
    func getSessionToken() -> String? {
        return billingService.getSKUTokenIfValid()
    }
    
    func beginBillingSession(type: SessionType) {
        beginBillingSession(type: type, increaseCount: true)
    }

    private func beginBillingSession(type: SessionType, increaseCount: Bool) {
        lock.lock()
        _sessionState = .running
        _sessionType = type
        if increaseCount {
            _startedSessionCount += 1
        }
        lock.unlock()

        billingService.triggerBillingEvent(onError: { error in
            print(error)
        })
        billingService.beginBillingSession(sessionType: type, onError: { [weak self] error in
            self?.failedToBeginBillingSession(with: error)
        })
    }

    private func failedToBeginBillingSession(with error: Error) {
        lock.lock(); defer {
            lock.unlock()
        }
        _sessionState = .stopped
    }
    
    func stopBillingSession() {
        lock.lock()
        _startedSessionCount -= 1
        guard _startedSessionCount == 0 else {
            lock.unlock(); return
        }
        _sessionState = .stopped
        lock.unlock()
        billingService.stopBillingSession()
    }
    
    func pauseBillingSession() {
        lock.lock()
        _sessionState = .paused
        lock.unlock()
        billingService.pauseBillingSession()
    }

    func resumeBillingSession() {
        lock.lock()
        _sessionState = .running
        lock.unlock()

        billingService.resumeBillingSession { _ in
            self.failedToResumeBillingSession()
        }
    }

    private func failedToResumeBillingSession() {
        lock.lock()
        _sessionState = .stopped
        let sessionType = _sessionType
        lock.unlock()

        beginBillingSession(type: sessionType, increaseCount: false)
    }
}

