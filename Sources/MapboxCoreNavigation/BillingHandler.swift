import Foundation
import MapboxDirections
@_implementationOnly import MapboxCommon_Private

/// BillingService from MapboxCommon
private typealias BillingServiceNative = MapboxCommon_Private.BillingService
/// BillingServiceError from MapboxCommon
private typealias BillingServiceErrorNative = MapboxCommon_Private.BillingServiceError

/// Swift variant of `BillingServiceErrorNative`
enum BillingServiceError: Error {
    /// Unknown error from Billing Service
    case unknown

    /// Provided SKU ID is invalid.
    case invalidSkuId
    /// The request failed because the access token is invalid.
    case tokenValidationFailed
    /// The resume failed because the session doesn't exist or invalid.
    case resumeFailed

    fileprivate init(_ nativeError: BillingServiceErrorNative) {
        switch nativeError.code {
        case .invalidSkuId:
            self = .invalidSkuId
        case .resumeFailed:
            self = .resumeFailed
        case .tokenValidationFailed:
            self = .tokenValidationFailed
        @unknown default:
            self = .unknown
        }
    }
}

/// Protocol for `BillingServiceNative` implementation. Inversing the dependency on `BillingServiceNative` allows us
/// to unit test our implementation.
protocol BillingService {
    func getSKUTokenIfValid() -> String
    func beginBillingSession(sessionType: BillingHandler.SessionType,
                             onError: @escaping (BillingServiceError) -> Void)
    func pauseBillingSession()
    func resumeBillingSession(onError: @escaping (BillingServiceError) -> Void)
    func stopBillingSession()
    func triggerBillingEvent(onError: @escaping (BillingServiceError) -> Void)
}

/// Implementation of `BillingService` protocol which uses `BillingServiceNative`.
private final class ProductionBillingService: BillingService {
    /// Mapbox access token which will be included in the billing requests.
    private let accessToken: String
    /// The User Agent string which will be included in the billing requests.
    private let userAgent: String
    /// `SKUIdentifier` which is used for navigation trips.
    private let tripSku: SKUIdentifier = .nav2SesTrip
    /// `SKUIdentifier` which is used for navigation MAU billing events.
    private let mauSku: SKUIdentifier = .nav2SesMAU

    init(accessToken: String, userAgent: String) {
        self.accessToken = accessToken
        self.userAgent = userAgent
    }

    func getSKUTokenIfValid() -> String {
        TokenGenerator.getSKUTokenIfValid(for: tripSku)
    }

    func beginBillingSession(sessionType: BillingHandler.SessionType,
                             onError: @escaping (BillingServiceError) -> Void) {
        print(">>>> Beging Billing Session: \(sessionType)")
        BillingServiceNative.beginBillingSession(forAccessToken: accessToken,
                                                 userAgent: userAgent,
                                                 skuIdentifier: tripSku,
                                                 callback: { nativeBillingServiceError in
                                                    onError(BillingServiceError(nativeBillingServiceError))
                                                 }, validity: sessionType.maxSessionInterval)
    }
    func pauseBillingSession() {
        BillingServiceNative.pauseBillingSession(for: tripSku)
        print(">>>> Pause Billing Session")
    }

    func resumeBillingSession(onError: @escaping (BillingServiceError) -> Void) {
        BillingServiceNative.resumeBillingSession(for: tripSku) { nativeBillingServiceError in
            onError(BillingServiceError(nativeBillingServiceError))
        }
        print(">>>> Resume Billing Session")
    }
    func stopBillingSession() {
        print(">>>> Stop Billing Session")
        BillingServiceNative.stopBillingSession(for: tripSku)
    }

    func triggerBillingEvent(onError: @escaping (BillingServiceError) -> Void) {
        print(">>>> MAU Event")
        BillingServiceNative.triggerBillingEvent(forAccessToken: accessToken,
                                                 userAgent: userAgent,
                                                 skuIdentifier: mauSku) { nativeBillingServiceError in
            onError(BillingServiceError(nativeBillingServiceError))
        }
    }
}

/// Receives events about navigation changes and triggers appropriate events in `BillingService`.
///
/// State of the billing sessions can be obtained using `BillingHandler.sessionState` property.
final class BillingHandler {
    /// The state of the billing session
    enum SessionState: Equatable {
        /// Indicates that there is no active billing session.
        case stopped
        /// There is an active paused billing session.
        case paused
        /// There is an active running billing session.
        case running
    }

    enum SessionType: Equatable {
        case freeDrive
        case activeGuidance

        var maxSessionInterval: TimeInterval {
            switch self {
            case .activeGuidance:
                return 43200 /*12h*/
            case .freeDrive:
                return 3600 /*2h*/
            }
        }
    }

    /// Shared billing handler instance. There is no other instances of `BillingHandler`.
    private(set) static var shared: BillingHandler = {
        let accessToken = Directions.shared.credentials.accessToken
        precondition(accessToken != nil, "A Mapbox access token is required. Go to <https://account.mapbox.com/access-tokens/>. In Info.plist, set the MBXAccessToken key to your access token.")
        let service = ProductionBillingService(accessToken: accessToken ?? "",
                                               userAgent: URLSession.userAgent)
        return .init(service: service)
    }()

    private let billingService: BillingService

    /// A lock which serialize access to variables with underscore: `_startedSessionCount`, `_sessionState` etc.
    private let lock: NSLock = .init()
    private var _startedSessionCount: Int = 0
    private var _sessionState: SessionState
    private var _sessionType: SessionType

    /// The session state of the `BillingService`.
    ///
    /// This variable is safe to use from any thread.
    /// Currently the state is managed on the NavSDK side, but will be replace with `MapboxCommon` implementation once
    /// available.
    var sessionState: SessionState {
        lock.lock(); defer {
            lock.unlock()
        }

        return _sessionState
    }

    var sessionToken: String {
        billingService.getSKUTokenIfValid()
    }
    
    private init(service: BillingService) {
        self.billingService = service
        self._sessionState = .stopped
        self._sessionType = .freeDrive
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

    private func failedToBeginBillingSession(with error: Error) {
        lock.lock(); defer {
            lock.unlock()
        }
        _sessionState = .stopped
    }

    private func failedToResumeBillingSession() {
        lock.lock()
        _sessionState = .stopped
        let sessionType = _sessionType
        lock.unlock()

        beginBillingSession(type: sessionType, increaseCount: false)
    }
}

// MARK: - Tests support

extension BillingHandler {
    static func __createMockedHandler(with service: BillingService) -> BillingHandler {
        BillingHandler(service: service)
    }

    static func __replaceShareInstance(with handler: BillingHandler) {
        BillingHandler.shared = handler
    }
}
