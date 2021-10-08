// IMPORTANT: Tampering with any file that contains billing code is a violation of our ToS
// and will result in enforcement of the penalties stipulated in the ToS.

import Foundation
import MapboxDirections
import os.log
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
    var accessToken: String { get }
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
    let accessToken: String

    /// The User Agent string which will be included in the billing requests.
    private let userAgent: String
    /// `SKUIdentifier` which is used for navigation MAU billing events.
    private let mauSku: SKUIdentifier = .nav2SesMAU

    /**
     Creates a new instance of `ProductionBillingService` which uses provided `accessToken` and `userAgent` for
     billing requests.

     - Parameters:
     - accessToken: Mapbox access token which will be included in the billing requests.
     - userAgent: The User Agent string which will be included in the billing requests.
     */
    init(accessToken: String, userAgent: String) {
        self.accessToken = accessToken
        self.userAgent = userAgent
    }

    func getSKUTokenIfValid(for sessionType: BillingHandler.SessionType) -> String {
        MapboxCommon_Private.BillingService.getSessionSKUTokenIfValid(for: tripSku(for: sessionType))
    }

    func beginBillingSession(for sessionType: BillingHandler.SessionType,
                             onError: @escaping (BillingServiceError) -> Void) {
        let skuToken = tripSku(for: sessionType)
        BillingServiceNative.beginBillingSession(forAccessToken: accessToken,
                                                 userAgent: userAgent,
                                                 skuIdentifier: skuToken,
                                                 callback: { nativeBillingServiceError in
                                                    onError(BillingServiceError(nativeBillingServiceError))
                                                 }, validity: sessionType.maxSessionInterval)
    }

    func pauseBillingSession(for sessionType: BillingHandler.SessionType) {
        let skuToken = tripSku(for: sessionType)
        BillingServiceNative.pauseBillingSession(for: skuToken)
    }

    func resumeBillingSession(for sessionType: BillingHandler.SessionType,
                              onError: @escaping (BillingServiceError) -> Void) {
        let skuToken = tripSku(for: sessionType)
        BillingServiceNative.resumeBillingSession(for: skuToken) { nativeBillingServiceError in
            onError(BillingServiceError(nativeBillingServiceError))
        }
    }

    func stopBillingSession(for sessionType: BillingHandler.SessionType) {
        let skuToken = tripSku(for: sessionType)
        BillingServiceNative.stopBillingSession(for: skuToken)
    }

    func triggerBillingEvent(onError: @escaping (BillingServiceError) -> Void) {
        BillingServiceNative.triggerBillingEvent(forAccessToken: accessToken,
                                                 userAgent: userAgent,
                                                 skuIdentifier: mauSku) { nativeBillingServiceError in
            onError(BillingServiceError(nativeBillingServiceError))
        }
    }

    func getSessionStatus(for sessionType: BillingHandler.SessionType) -> BillingHandler.SessionState {
        switch BillingServiceNative.getSessionStatus(for: tripSku(for: sessionType)) {
        case .noSession: return .stopped
        case .sessionActive: return .running
        case .sessionPaused: return .paused
        @unknown default:
            preconditionFailure("Unsupported session status from BillingServiceNative")
        }
    }

    private func tripSku(for sessionType: BillingHandler.SessionType) -> SKUIdentifier {
        switch sessionType {
        case .activeGuidance:
            return .nav2SesTrip
        case .freeDrive:
            return .nav2SesFDTrip
        }
    }
}

/**
 Receives events about navigation changes and triggers appropriate events in `BillingService`.

 Session can be paused (`BillingHandler.pauseBillingSession(with:)`),
 stopped (`BillingHandler.stopBillingSession(with:)`) or
 resumed (`BillingHandler.resumeBillingSession(with:)`).

 State of the billing sessions can be obtained using `BillingHandler.sessionState(uuid:)`.
 */
final class BillingHandler {
    /// Parameters on an active session.
    private struct Session {
        let type: SessionType
        /// Indicates whether the session is active but paused.
        var isPaused: Bool
    }

    /// The state of the billing session.
    enum SessionState: Equatable {
        /// Indicates that there is no active billing session.
        case stopped
        /// There is an active paused billing session.
        case paused
        /// There is an active running billing session.
        case running
    }

    /// Supported session types.
    enum SessionType: Equatable {
        case freeDrive
        case activeGuidance

        var maxSessionInterval: TimeInterval {
            switch self {
            case .activeGuidance:
                return 43200 /*12h*/
            case .freeDrive:
                return 3600 /*1h*/
            }
        }
    }

    /// Shared billing handler instance. There is no other instances of `BillingHandler`.
    private(set) static var shared: BillingHandler = {
        let accessToken = NavigationSettings.shared.directions.credentials.accessToken
        precondition(accessToken != nil, "A Mapbox access token is required. Go to <https://account.mapbox.com/access-tokens/>. In Info.plist, set the MBXAccessToken key to your access token.")
        let service = ProductionBillingService(accessToken: accessToken ?? "",
                                               userAgent: URLSession.userAgent)
        return .init(service: service)
    }()

    /// The billing service which is used to send billing events.
    private let billingService: BillingService

    /**
     A lock which serializes access to variables with underscore: `_sessions` etc.
     As a convention, all class-level identifiers that starts with `_` should be executed with locked `lock`.
     */
    private let lock: NSLock = .init()

    /**
     All currently active sessions. Running or paused. When session is stopped, it is removed from this variable.
     These sessions are different from `BillingServiceNative` sessions. `BillingHandler.Session`s are mapped to one
     `BillingServiceNative`'s session for each `BillingHandler.SessionType`.
     */
    private var _sessions: [UUID: Session] = [:]

    private let logger: OSLog = .init(subsystem: "com.mapbox.navigation", category: "Billing")

    /**
     The state of the billing session.

     - important: This variable is safe to use from any thread.
     - parameter uuid: Session UUID which is provided in `BillingHandler.beginBillingSession(for:uuid:)`.
     */
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

    /// The token to use for service requests like `Directions` etc. 
    var serviceSkuToken: String {
        let sessionTypes: [BillingHandler.SessionType] = [.activeGuidance, .freeDrive]

        for sessionType in sessionTypes {
            switch billingService.getSessionStatus(for: sessionType) {
            case .running:
                return billingService.getSKUTokenIfValid(for: sessionType)
            case .paused, .stopped:
                continue
            }
        }

        return ""
    }

    /// Access token that matches `BillingHandler.serviceSkuToken`.
    var serviceAccessToken: String {
        billingService.accessToken
    }

    private init(service: BillingService) {
        self.billingService = service
    }

    /**
     Starts a new billing session of the given `sessionType` identified by `uuid`.

     The `uuid` that is used to create a billing session must be provided in the following methods to perform
     relevant changes to the started billing session:
     - `BillingHandler.stopBillingSession(with:)`
     - `BillingHandler.pauseBillingSession(with:)`
     - `BillingHandler.resumeBillingSession(with:)`

     - Parameters:
     - sessionType: The type of the billing session.
     - uuid: The unique identifier of the billing session.
     */
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

        let sessionStatus = billingService.getSessionStatus(for: sessionType)

        lock.unlock()

        switch sessionStatus {
        case .stopped:
            billingService.triggerBillingEvent(onError: { [logger] error in
                os_log("MAU isn't counted", log: logger, type: .fault)
            })
            billingService.beginBillingSession(for: sessionType, onError: { [weak self, logger] error in
                os_log("Trip session isn't started. Please check that you have the correct Mapboox Access Token",
                       log: logger,
                       type: .fault)

                switch error {
                case .invalidSkuId:
                    preconditionFailure("Invalid sku_id: \(error)")
                case .tokenValidationFailed:
                    assertionFailure("Token validation failed. Please check that you have the correct Mapboox Access Token.")
                case .resumeFailed, .unknown:
                    break
                }
                self?.failedToBeginBillingSession(with: uuid, with: error)
            })
        case .paused:
            resumeBillingSession(with: uuid)
        case .running:
            break
        }
    }

    /**
     Starts a new billing session in `billingService` if a session with `uuid` exists and active.

     Use this method to force `billingService` to start a new billing session. 
     */
    func beginNewBillingSessionIfRunning(with uuid: UUID) {
        lock.lock()

        guard let session = _sessions[uuid], !session.isPaused else {
            return
        }

        lock.unlock()

        billingService.beginBillingSession(for: session.type) { [logger] error in
            os_log("New trip session isn't started. Please check that you have the correct Mapboox Access Token.",
                   log: logger,
                   type: .fault)

            switch error {
            case .invalidSkuId:
                preconditionFailure("Invalid sku_id: \(error)")
            case .tokenValidationFailed:
                assertionFailure("Token validation failed. Please check that you have the correct Mapboox Access Token.")
            case .resumeFailed, .unknown:
                break
            }
        }
    }

    /// Stops the billing session identified by the `uuid`.
    func stopBillingSession(with uuid: UUID) {
        lock.lock()
        guard let session = _sessions[uuid] else {
            lock.unlock(); return
        }
        _sessions[uuid] = nil

        let hasSessionWithSameType = _hasSession(with: session.type)
        let triggerStopSessionEvent = !hasSessionWithSameType
            && billingService.getSessionStatus(for: session.type) != .stopped
        let triggerPauseSessionEvent =
            !triggerStopSessionEvent
            && hasSessionWithSameType
            && !_hasSession(with: session.type, isPaused: false)
            && billingService.getSessionStatus(for: session.type) != .paused
        lock.unlock()

        if triggerStopSessionEvent {
            billingService.stopBillingSession(for: session.type)
        }
        else if triggerPauseSessionEvent {
            billingService.pauseBillingSession(for: session.type)
        }
    }
 
    /// Pauses the billing session identified by the `uuid`.
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
    
    /// Resumes the billing session identified by the `uuid`.
    func resumeBillingSession(with uuid: UUID) {
        lock.lock()
        guard var session = _sessions[uuid] else {
            assertionFailure("Trying to resume non-existing session.")
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
        lock {
            _sessions[uuid] = nil
        }
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

    private func _hasSession(with type: SessionType) -> Bool {
        return _sessions.contains(where: { $0.value.type == type })
    }

    private func _hasSession(with type: SessionType, isPaused: Bool) -> Bool {
        return _sessions.values.contains { session in
            session.type == type && session.isPaused == isPaused
        }
    }
}

// MARK: - Tests Support

extension BillingHandler {
    static func __createMockedHandler(with service: BillingService) -> BillingHandler {
        BillingHandler(service: service)
    }

    static func __replaceSharedInstance(with handler: BillingHandler) {
        BillingHandler.shared = handler
    }
}
