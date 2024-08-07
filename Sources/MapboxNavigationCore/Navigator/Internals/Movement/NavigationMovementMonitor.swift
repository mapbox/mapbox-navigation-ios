import _MapboxNavigationHelpers
import Foundation
import MapboxCommon_Private
import MapboxDirections

final class NavigationMovementMonitor: MovementMonitorInterface {
    private var observers: [any MovementModeObserver] {
        _observers.read()
    }

    var currentProfile: ProfileIdentifier? {
        get {
            _currentProfile.read()
        }
        set {
            _currentProfile.update(newValue)
            notify(with: movementInfo)
        }
    }

    private let _observers: UnfairLocked<[any MovementModeObserver]> = .init([])
    private let _currentProfile: UnfairLocked<ProfileIdentifier?> = .init(nil)
    private let _customMovementInfo: UnfairLocked<MovementInfo?> = .init(nil)

    func getMovementInfo(forCallback callback: @escaping MovementInfoCallback) {
        callback(.init(value: movementInfo))
    }

    func setMovementInfoForMode(_ movementInfo: MovementInfo) {
        _customMovementInfo.update(movementInfo)
        notify(with: movementInfo)
    }

    func registerObserver(for observer: any MovementModeObserver) {
        _observers.mutate {
            $0.append(observer)
        }
    }

    func unregisterObserver(for observer: any MovementModeObserver) {
        _observers.mutate {
            $0.removeAll(where: { $0 === observer })
        }
    }

    private func notify(with movementInfo: MovementInfo) {
        let currentObservers = observers
        currentObservers.forEach {
            $0.onMovementModeChanged(for: movementInfo)
        }
    }

    private var movementInfo: MovementInfo {
        if let customMovementInfo = _customMovementInfo.read() {
            return customMovementInfo
        }
        let profile = currentProfile
        let movementModes: [NSNumber: NSNumber] = if let movementMode = profile?.movementMode {
            [100: movementMode.rawValue as NSNumber]
        } else if profile != nil {
            [50: MovementMode.inVehicle.rawValue as NSNumber]
        } else {
            [50: MovementMode.unknown.rawValue as NSNumber]
        }
        return MovementInfo(movementMode: movementModes, movementProvider: .SDK)
    }
}

extension MovementInfo: @unchecked Sendable {}

extension ProfileIdentifier {
    var movementMode: MovementMode? {
        switch self {
        case .automobile, .automobileAvoidingTraffic:
            .inVehicle
        case .cycling:
            .cycling
        case .walking:
            .onFoot
        default:
            nil
        }
    }
}
