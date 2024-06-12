// IMPORTANT: Tampering with any file that contains billing code is a violation of our ToS
// and will result in enforcement of the penalties stipulated in the ToS.

import Foundation
import MapboxCommon_Private
import MapboxDirections

/// Wrapper around `MapboxCommon_Private.BillingServiceFactory`, which provides its shared instance.
enum NativeBillingService {
    /// Provides a new or an existing `MapboxCommon`s `BillingServiceFactory` instance.
    static var shared: MapboxCommon_Private.BillingService {
        MapboxCommon_Private.BillingServiceFactory.getInstance()
    }
}

/// BillingServiceError from MapboxCommon
private typealias BillingServiceErrorNative = MapboxCommon_Private.BillingServiceError

/// Swift variant of `BillingServiceErrorNative`
enum BillingServiceError: Error {
    /// Unknown error from Billing Service
    case unknown
    /// The request failed because the access token is invalid.
    case tokenValidationFailed
    /// The resume failed because the session doesn't exist or invalid.
    case resumeFailed

    fileprivate init(_ nativeError: BillingServiceErrorNative) {
        switch nativeError.code {
        case .resumeFailed:
            self = .resumeFailed
        case .tokenValidationFailed:
            self = .tokenValidationFailed
        @unknown default:
            self = .unknown
        }
    }
}

/// Protocol for `NativeBillingService` implementation. Inversing the dependency on `NativeBillingService` allows us
/// to unit test our implementation.
protocol BillingService: Sendable {
    func getSKUTokenIfValid(for sessionType: BillingHandler.SessionType) -> String
    func beginBillingSession(
        for sessionType: BillingHandler.SessionType,
        onError: @escaping (BillingServiceError) -> Void
    )
    func pauseBillingSession(for sessionType: BillingHandler.SessionType)
    func resumeBillingSession(
        for sessionType: BillingHandler.SessionType,
        onError: @escaping (BillingServiceError) -> Void
    )
    func stopBillingSession(for sessionType: BillingHandler.SessionType)
    func triggerBillingEvent(onError: @escaping (BillingServiceError) -> Void)
    func getSessionStatus(for sessionType: BillingHandler.SessionType) -> BillingHandler.SessionState
}

/// Implementation of `BillingService` protocol which uses `NativeBillingService`.
private final class ProductionBillingService: BillingService {
    /// `UserSKUIdentifier` which is used for navigation MAU billing events.
    private let mauSku: UserSKUIdentifier = .nav3CoreMAU
    private var sdkInformation: SdkInformation {
        .init(
            name: SdkInfo.navigationUX.name,
            version: SdkInfo.navigationUX.version,
            packageName: SdkInfo.navigationUX.packageName
        )
    }

    init() {}

    func getSKUTokenIfValid(for sessionType: BillingHandler.SessionType) -> String {
        NativeBillingService.shared.getSessionSKUTokenIfValid(for: tripSku(for: sessionType))
    }

    func beginBillingSession(
        for sessionType: BillingHandler.SessionType,
        onError: @escaping (BillingServiceError) -> Void
    ) {
        let skuToken = tripSku(for: sessionType)
        Log.info("\(sessionType) billing session starts", category: .billing)

        NativeBillingService.shared.beginBillingSession(
            for: sdkInformation,
            skuIdentifier: skuToken,
            callback: {
                nativeBillingServiceError in
                onError(BillingServiceError(nativeBillingServiceError))
            },
            validity: sessionType.maxSessionInterval
        )
    }

    func pauseBillingSession(for sessionType: BillingHandler.SessionType) {
        let skuToken = tripSku(for: sessionType)
        Log.info("\(sessionType) billing session pauses", category: .billing)
        NativeBillingService.shared.pauseBillingSession(for: skuToken)
    }

    func resumeBillingSession(
        for sessionType: BillingHandler.SessionType,
        onError: @escaping (BillingServiceError) -> Void
    ) {
        let skuToken = tripSku(for: sessionType)
        Log.info("\(sessionType) billing session resumes", category: .billing)
        NativeBillingService.shared.resumeBillingSession(for: skuToken) { nativeBillingServiceError in
            onError(BillingServiceError(nativeBillingServiceError))
        }
    }

    func stopBillingSession(for sessionType: BillingHandler.SessionType) {
        let skuToken = tripSku(for: sessionType)
        Log.info("\(sessionType) billing session stops", category: .billing)
        NativeBillingService.shared.stopBillingSession(for: skuToken)
    }

    func triggerBillingEvent(onError: @escaping (BillingServiceError) -> Void) {
        NativeBillingService.shared.triggerUserBillingEvent(
            for: sdkInformation,
            skuIdentifier: mauSku
        ) { nativeBillingServiceError in
            onError(BillingServiceError(nativeBillingServiceError))
        }
    }

    func getSessionStatus(for sessionType: BillingHandler.SessionType) -> BillingHandler.SessionState {
        switch NativeBillingService.shared.getSessionStatus(for: tripSku(for: sessionType)) {
        case .noSession: return .stopped
        case .sessionActive: return .running
        case .sessionPaused: return .paused
        @unknown default:
            preconditionFailure("Unsupported session status from NativeBillingService.")
        }
    }

    private func tripSku(for sessionType: BillingHandler.SessionType) -> SessionSKUIdentifier {
        switch sessionType {
        case .activeGuidance:
            return .nav3SesCoreAGTrip
        case .freeDrive:
            return .nav3SesCoreFDTrip
        }
    }
}

/// Receives events about navigation changes and triggers appropriate events in `BillingService`.
///
/// Session can be paused (`BillingHandler.pauseBillingSession(with:)`), stopped
/// (`BillingHandler.stopBillingSession(with:)`) or resumed (`BillingHandler.resumeBillingSession(with:)`).
///
/// State of the billing sessions can be obtained using `BillingHandler.sessionState(uuid:)`.
final class BillingHandler: @unchecked Sendable {
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
    enum SessionType: Equatable, CustomStringConvertible {
        case freeDrive
        case activeGuidance

        var maxSessionInterval: TimeInterval {
            switch self {
            case .activeGuidance:
                return 43200 /* 12h */
            case .freeDrive:
                return 3600 /* 1h */
            }
        }

        var description: String {
            switch self {
            case .activeGuidance:
                return "Active Guidance"
            case .freeDrive:
                return "Free Drive"
            }
        }
    }

    static func createInstance(with accessToken: String?) -> BillingHandler {
        precondition(
            accessToken != nil,
            "A Mapbox access token is required. Go to <https://account.mapbox.com/access-tokens/>. In Info.plist, set the MBXAccessToken key to your access token."
        )
        let service = ProductionBillingService()
        return .init(service: service)
    }

    /// The billing service which is used to send billing events.
    private let billingService: BillingService

    /// A lock which serializes access to variables with underscore: `_sessions` etc.
    /// As a convention, all class-level identifiers that starts with `_` should be executed with locked `lock`.
    private let lock: NSLock = .init()

    /// All currently active sessions. Running or paused. When session is stopped, it is removed from this variable.
    /// These sessions are different from `NativeBillingService` sessions. `BillingHandler.Session`s are mapped to one
    /// `NativeBillingService`'s session for each `BillingHandler.SessionType`.
    private var _sessions: [UUID: Session] = [:]

    /// The state of the billing session.
    ///
    /// - Important: This variable is safe to use from any thread.
    /// - Parameter uuid: Session UUID which is provided in `BillingHandler.beginBillingSession(for:uuid:)`.
    func sessionState(uuid: UUID) -> SessionState {
        lock.lock(); defer {
            lock.unlock()
        }

        guard let session = _sessions[uuid] else {
            return .stopped
        }

        if session.isPaused {
            return .paused
        } else {
            return .running
        }
    }

    func sessionType(uuid: UUID) -> SessionType? {
        lock.lock(); defer {
            lock.unlock()
        }

        guard let session = _sessions[uuid] else {
            return nil
        }
        return session.type
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

    private init(service: BillingService) {
        self.billingService = service
    }

    /// Starts a new billing session of the given `sessionType` identified by `uuid`.
    ///
    /// The `uuid` that is used to create a billing session must be provided in the following methods to perform
    /// relevant changes to the started billing session:
    /// - `BillingHandler.stopBillingSession(with:)`
    /// - `BillingHandler.pauseBillingSession(with:)`
    /// - `BillingHandler.resumeBillingSession(with:)`
    ///
    /// - Parameters:
    ///   - sessionType: The type of the billing session.
    ///   - uuid: The unique identifier of the billing session.
    func beginBillingSession(for sessionType: SessionType, uuid: UUID) {
        lock.lock()

        if var existingSession = _sessions[uuid] {
            existingSession.isPaused = false
            _sessions[uuid] = existingSession
        } else {
            let session = Session(type: sessionType, isPaused: false)
            _sessions[uuid] = session
        }

        let sessionStatus = billingService.getSessionStatus(for: sessionType)

        lock.unlock()

        switch sessionStatus {
        case .stopped:
            billingService.triggerBillingEvent(onError: { _ in
                Log.fault("MAU isn't counted", category: .billing)
            })
            billingService.beginBillingSession(for: sessionType, onError: { [weak self] error in
                Log.fault(
                    "Trip session isn't started. Please check that you have the correct Mapboox Access Token",
                    category: .billing
                )

                switch error {
                case .tokenValidationFailed:
                    assertionFailure(
                        "Token validation failed. Please check that you have the correct Mapbox Access Token."
                    )
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

    /// Starts a new billing session in `billingService` if a session with `uuid` exists.
    ///
    /// Use this method to force `billingService` to start a new billing session.
    func beginNewBillingSessionIfExists(with uuid: UUID) {
        lock.lock()

        guard let session = _sessions[uuid] else {
            lock.unlock(); return
        }

        lock.unlock()

        billingService.beginBillingSession(for: session.type) { error in
            Log.fault(
                "New trip session isn't started. Please check that you have the correct Mapboox Access Token.",
                category: .billing
            )

            switch error {
            case .tokenValidationFailed:
                assertionFailure(
                    "Token validation failed. Please check that you have the correct Mapboox Access Token."
                )
            case .resumeFailed, .unknown:
                break
            }
        }

        if session.isPaused {
            pauseBillingSession(with: uuid)
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
        } else if triggerPauseSessionEvent {
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

    func shouldStartNewBillingSession(for newRoute: Route, remainingWaypoints: [Waypoint]) -> Bool {
        let newRouteWaypoints = newRoute.legs.compactMap(\.destination)

        guard !newRouteWaypoints.isEmpty else {
            return false // Don't need to bil for routes without waypoints
        }

        guard newRouteWaypoints.count == remainingWaypoints.count else {
            Log.info(
                "A new route is about to be set with a different set of waypoints, leading to the initiation of a new Active Guidance trip. For more information, see the “[Pricing](https://docs.mapbox.com/ios/beta/navigation/guides/pricing/)” guide.",
                category: .billing
            )
            return true
        }

        for (newWaypoint, currentWaypoint) in zip(newRouteWaypoints, remainingWaypoints) {
            if newWaypoint.coordinate.distance(to: currentWaypoint.coordinate) > 100 {
                Log.info(
                    "A new route waypoint \(newWaypoint) is further than 100 meters from current waypoint \(currentWaypoint), leading to the initiation of a new Active Guidance trip. For more information, see the “[Pricing](https://docs.mapbox.com/ios/navigation/guides/pricing/)” guide. ",
                    category: .billing
                )
                return true
            }
        }

        return false
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
}
