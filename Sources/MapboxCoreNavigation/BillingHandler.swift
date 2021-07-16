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
    func getSKUTokenIfValid(for sessionType: BillingHandler.SessionType) -> String
    func beginBillingSession(for sessionType: BillingHandler.SessionType,
                             onError: @escaping (BillingServiceError) -> Void)
    func pauseBillingSession(for sessionType: BillingHandler.SessionType)
    func resumeBillingSession(for sessionType: BillingHandler.SessionType,
                              onError: @escaping (BillingServiceError) -> Void)
    func stopBillingSession(for sessionType: BillingHandler.SessionType)
    func triggerBillingEvent(onError: @escaping (BillingServiceError) -> Void)
    func getSessionStatus(for sessionType: BillingHandler.SessionType) -> BillingHandler.SessionState
}

/// Implementation of `BillingService` protocol which uses `BillingServiceNative`.
private final class ProductionBillingService: BillingService {
    /// Mapbox access token which will be included in the billing requests.
    private let accessToken: String
    /// The User Agent string which will be included in the billing requests.
    private let userAgent: String
    /// `SKUIdentifier` which is used for navigation MAU billing events.
    private let mauSku: SKUIdentifier = .nav2SesMAU

    private var sessionState: [SKUIdentifier: BillingHandler.SessionState] = [:]

    init(accessToken: String, userAgent: String) {
        self.accessToken = accessToken
        self.userAgent = userAgent
    }

    func getSKUTokenIfValid(for sessionType: BillingHandler.SessionType) -> String {
        return TokenGenerator.getSKUTokenIfValid(for: tripSku(for: sessionType))
    }

    func beginBillingSession(for sessionType: BillingHandler.SessionType,
                             onError: @escaping (BillingServiceError) -> Void) {
        let skuToken = tripSku(for: sessionType)
        sessionState[skuToken] = .running
        print(">>>> Beging Billing Session: \(sessionType)")
        BillingServiceNative.beginBillingSession(forAccessToken: accessToken,
                                                 userAgent: userAgent,
                                                 skuIdentifier: skuToken,
                                                 callback: { [weak self] nativeBillingServiceError in
                                                    self?.sessionState[skuToken] = .stopped
                                                    onError(BillingServiceError(nativeBillingServiceError))
                                                 }, validity: sessionType.maxSessionInterval)
    }

    func pauseBillingSession(for sessionType: BillingHandler.SessionType) {
        print(">>>> Pause Billing Session")
        let skuToken = tripSku(for: sessionType)
        sessionState[skuToken] = .paused
        BillingServiceNative.pauseBillingSession(for: skuToken)
    }

    func resumeBillingSession(for sessionType: BillingHandler.SessionType,
                              onError: @escaping (BillingServiceError) -> Void) {
        let skuToken = tripSku(for: sessionType)
        BillingServiceNative.resumeBillingSession(for: skuToken) { [weak self] nativeBillingServiceError in
            self?.sessionState[skuToken] = .stopped
            onError(BillingServiceError(nativeBillingServiceError))
        }
        print(">>>> Resume Billing Session")
    }

    func stopBillingSession(for sessionType: BillingHandler.SessionType) {
        let skuToken = tripSku(for: sessionType)
        sessionState[skuToken] = .stopped
        print(">>>> Stop Billing Session")
        BillingServiceNative.stopBillingSession(for: skuToken)
    }

    func triggerBillingEvent(onError: @escaping (BillingServiceError) -> Void) {
        print(">>>> MAU Event")
        BillingServiceNative.triggerBillingEvent(forAccessToken: accessToken,
                                                 userAgent: userAgent,
                                                 skuIdentifier: mauSku) { nativeBillingServiceError in
            onError(BillingServiceError(nativeBillingServiceError))
        }
    }

    func getSessionStatus(for sessionType: BillingHandler.SessionType) -> BillingHandler.SessionState {
        return sessionState[tripSku(for: sessionType)] ?? .stopped
    }

    private func tripSku(for sessionType: BillingHandler.SessionType) -> SKUIdentifier {
        switch sessionType {
        case .activeGuidance:
            return .nav2SesTrip
        case .freeDrive:
            return .nav2SesTrip
        }
    }
}

/// Receives events about navigation changes and triggers appropriate events in `BillingService`.
///
/// State of the billing sessions can be obtained using `BillingHandler.sessionState` property.
final class BillingHandler {
    private struct Session {
        let type: SessionType
        var isPaused: Bool
    }

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

    /// A lock which serialize access to variables with underscore: `_sessions` etc.
    /// As a convention, all class-level identifiers that starts with `_` should be executed with locked `lock`.
    private let lock: NSLock = .init()

    /// All currently active sessions. Running or paused. When session is stopped, it is removed from this variable.
    private var _sessions: [UUID: Session] = [:]

    /// The session state of the `BillingService`.
    ///
    /// This variable is safe to use from any thread.
    /// Currently the state is managed on the NavSDK side, but will be replace with `MapboxCommon` implementation once
    /// available.
    /// - parameter uuid: Session UUID which is provided in ???
    #warning("uuid parameter doc finish")
    func sessionState(uuid: UUID) -> SessionState {
        lock.lock(); defer {
            lock.unlock()
        }

        guard let session = _sessions[uuid] else {
            return .stopped
        }

        if session.isPaused {
            return .paused
        }
        else {
            return .running
        }
    }

    var sessionToken: String {
        lock.lock()
        let sessionType = _sessionTypeForRequests()
        lock.unlock()
        
        if let sessionType = sessionType {
            return billingService.getSKUTokenIfValid(for: sessionType)
        }
        else {
            return ""
        }
    }
    
    private init(service: BillingService) {
        self.billingService = service
    }
    
    func beginBillingSession(for sessionType: SessionType, uuid: UUID) {
        lock.lock()

        if var existingSession = _sessions[uuid] {
            existingSession.isPaused = false
            _sessions[uuid] = existingSession
        }
        else {
            let session = Session(type: sessionType, isPaused: false)
            _sessions[uuid] = session
        }
        lock.unlock()

        let triggerBillingServiceEvents = billingService.getSessionStatus(for: sessionType) != .running
        if triggerBillingServiceEvents {
            billingService.triggerBillingEvent(onError: { error in
                print(error)
            })
            billingService.beginBillingSession(for: sessionType, onError: { [weak self] error in
                self?.failedToBeginBillingSession(with: uuid, with: error)
            })
        }
    }
    
    func stopBillingSession(with uuid: UUID) {
        lock.lock()
        guard let session = _sessions[uuid] else {
            assertionFailure("Trying to stop non started session.");
            lock.unlock(); return
        }
        _sessions[uuid] = nil

        if !_hasSession(with: session.type) && billingService.getSessionStatus(for: session.type) != .stopped {
            billingService.stopBillingSession(for: session.type)
        }
        lock.unlock()
    }
    
    func pauseBillingSession(with uuid: UUID) {
        lock.lock()
        guard var session = _sessions[uuid] else {
            assertionFailure("Trying to pause non-existing session.")
            lock.unlock(); return
        }
        session.isPaused = true
        _sessions[uuid] = session


        let triggerBillingServiceEvent = !_hasSession(with: session.type, isPaused: false)
            && billingService.getSessionStatus(for: session.type) == .running
        lock.unlock()

        if triggerBillingServiceEvent {
            billingService.pauseBillingSession(for: session.type)
        }
    }

    func resumeBillingSession(with uuid: UUID) {
        lock.lock()
        guard var session = _sessions[uuid] else {
            assertionFailure("Trying to pause non-existing session.")
            lock.unlock(); return
        }
        session.isPaused = false
        _sessions[uuid] = session
        let triggerBillingServiceEvent = billingService.getSessionStatus(for: session.type) == .paused
        lock.unlock()

        if triggerBillingServiceEvent {
            billingService.resumeBillingSession(for: session.type) { _ in
                self.failedToResumeBillingSession(with: uuid)
            }
        }
    }

    private func failedToBeginBillingSession(with uuid: UUID, with error: Error) {
        lock.lock(); defer {
            lock.unlock()
        }
        _sessions[uuid] = nil
    }

    private func failedToResumeBillingSession(with uuid: UUID) {
        lock.lock()
        guard let session = _sessions[uuid] else {
            lock.unlock(); return
        }
        _sessions[uuid] = nil
        lock.unlock()
        beginBillingSession(for: session.type, uuid: uuid)
    }

    private func _sessionTypeForRequests() -> SessionType? {
        for session in _sessions.values {
            if session.type == .activeGuidance {
                return .activeGuidance
            }
        }
        if _sessions.isEmpty {
            return nil
        }
        else {
            return .freeDrive
        }
    }

    private func _hasSession(with type: SessionType) -> Bool {
        return _sessions.contains(where: { $0.value.type == type })
    }

    private func _hasSession(with type: SessionType, isPaused: Bool) -> Bool {
        return _sessions.values.contains { session in
            session.type == type && session.isPaused == isPaused
        }
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
