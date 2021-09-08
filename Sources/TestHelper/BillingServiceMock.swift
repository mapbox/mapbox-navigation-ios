import Foundation
import XCTest
@testable import MapboxCoreNavigation

public final class BillingServiceMock: BillingService {
    public enum Event: Equatable, CustomStringConvertible {
        case beginBillingSession(BillingHandler.SessionType)
        case stopBillingSession(BillingHandler.SessionType)
        case pauseBillingSession(BillingHandler.SessionType)
        case resumeBillingSession(BillingHandler.SessionType)
        case mau

        public var description: String {
            switch self {
            case .beginBillingSession(let sessionType):
                return "Begin \(sessionType)"
            case .stopBillingSession(let sessionType):
                return "Stop \(sessionType)"
            case .pauseBillingSession(let sessionType):
                return "Pause \(sessionType)"
            case .resumeBillingSession(let sessionType):
                return "Resume \(sessionType)"
            case .mau:
                return "MAU"
            }
        }
    }

    private let lock: NSLock = .init()
    private var _sessionStates: [BillingHandler.SessionType: BillingHandler.SessionState] = [:]
    private var _events: [Event] = []

    public var accessToken: String = .mockedAccessToken
    public var onBeginBillingSession: ((_ sessionType: BillingHandler.SessionType,
                                        _ callback: @escaping (BillingServiceError) -> Void) -> Void)?
    public var onGetSKUTokenIfValid: ((_ sessionType: BillingHandler.SessionType) -> String)?
    public var onStopBillingSession: ((_ sessionType: BillingHandler.SessionType) -> Void)?
    public var onTriggerBillingEvent: ((_ onError: @escaping (BillingServiceError) -> Void) -> Void)?
    public var onPauseBillingSession: ((_ sessionType: BillingHandler.SessionType) -> Void)?
    public var onResumeBillingSession: ((_ sessionType: BillingHandler.SessionType,
                                         _ onError: @escaping (BillingServiceError) -> Void) -> Void)?
    public var onGetSessionStatus: ((_ sessionType: BillingHandler.SessionType) -> BillingHandler.SessionState)?

    public init() {}

    public func getSKUTokenIfValid(for sessionType: BillingHandler.SessionType) -> String {
        onGetSKUTokenIfValid?(sessionType) ?? ""
    }

    public func stopBillingSession(for sessionType: BillingHandler.SessionType) {
        onStopBillingSession?(sessionType)
        generateEvent(.stopBillingSession(sessionType))
    }

    public func triggerBillingEvent(onError: @escaping (BillingServiceError) -> Void) {
        onTriggerBillingEvent?(onError)
        generateEvent(.mau)
    }

    public func beginBillingSession(for sessionType: BillingHandler.SessionType,
                                    onError: @escaping (BillingServiceError) -> Void) {
        generateEvent(.beginBillingSession(sessionType))
        onBeginBillingSession?(sessionType, { [unowned self] error in
            lock.lock(); _sessionStates[sessionType] = .stopped; lock.unlock()
            onError(error)
        })
    }

    public func pauseBillingSession(for sessionType: BillingHandler.SessionType) {
        generateEvent(.pauseBillingSession(sessionType))
        onPauseBillingSession?(sessionType)
    }

    public func resumeBillingSession(for sessionType: BillingHandler.SessionType,
                                     onError: @escaping (BillingServiceError) -> Void) {
        generateEvent(.resumeBillingSession(sessionType))
        onResumeBillingSession?(sessionType, { [unowned self] error in
            lock.lock(); _sessionStates[sessionType] = .stopped; lock.unlock()
            onError(error)
        })
    }

    public func getSessionStatus(for sessionType: BillingHandler.SessionType) -> BillingHandler.SessionState {
        onGetSessionStatus?(sessionType) ?? { () -> BillingHandler.SessionState in
            lock.lock(); defer {
                lock.unlock()
            }
            return _sessionStates[sessionType] ?? .stopped
        }()
    }

    /// Assert that generated events are equal to `events`. This excludes MAU events to simplify testing.
    public func assertEvents(_ events: [Event]) {
        XCTAssertEqual(events, _events.filter { $0 != .mau })
    }

    private func generateEvent(_ event: Event) {
        lock.lock(); defer {
            lock.unlock()
        }
        _events.append(event)
        switch event {
        case .beginBillingSession(let sessionType):
            _sessionStates[sessionType] = .running
        case .pauseBillingSession(let sessionType):
            _sessionStates[sessionType] = .paused
        case .resumeBillingSession(let sessionType):
            _sessionStates[sessionType] = .running
        case .stopBillingSession(let sessionType):
            _sessionStates[sessionType] = .stopped
        case .mau:
            break
        }
    }
}
