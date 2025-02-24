import Foundation
@_implementationOnly import MapboxCommon_Private
import MapboxDirections

final class NavigationMovementMonitor: MovementMonitorInterface {
    static let shared: NavigationMovementMonitor = {
        let movementMonitor = NavigationMovementMonitor()
        MovementMonitorFactory.setUserDefinedForCustom(movementMonitor)
        return movementMonitor
    }()

    private var observers: [any MovementModeObserver] = []
    private var customMovementInfo: MovementInfo? = nil

    private var _currentProfile: ProfileIdentifier? = nil
    private let queue: DispatchQueue

    init(queue: DispatchQueue = DispatchQueue(
        label: "com.mapbox.NavigationMovementMonitor",
        attributes: .concurrent
    )) {
        self.queue = queue
    }

    var currentProfile: ProfileIdentifier? {
        get {
            queue.sync {
                _currentProfile
            }
        }
        set {
            queue.async(flags: .barrier) { [weak self] in
                guard let self else { return }

                self._currentProfile = newValue
                self.notify(with: self.movementInfo)
            }
        }
    }

    func getMovementInfo(forCallback callback: @escaping MovementInfoCallback) {
        queue.async { [weak self] in
            guard let self else { return }

            callback(.init(value: self.movementInfo))
        }
    }

    func setMovementInfoForMode(_ movementInfo: MovementInfo) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }

            self.customMovementInfo = movementInfo
            self.notify(with: movementInfo)
        }
    }

    func registerObserver(for observer: any MovementModeObserver) {
        queue.async(flags: .barrier) { [weak self] in
            self?.observers.append(observer)
        }
    }

    func unregisterObserver(for observer: any MovementModeObserver) {
        queue.async(flags: .barrier) { [weak self] in
            self?.observers.removeAll(where: { $0 === observer })
        }
    }

    private func notify(with movementInfo: MovementInfo) {
        let currentObservers = observers
        for currentObserver in currentObservers {
            currentObserver.onMovementModeChanged(for: movementInfo)
        }
    }

    private var movementInfo: MovementInfo {
        if let customMovementInfo {
            return customMovementInfo
        }
        let profile = _currentProfile

        let movementModes: [NSNumber: NSNumber]
        if let movementMode = profile?.movementMode {
            movementModes = [movementMode.rawValue as NSNumber: 100]
        } else if profile != nil {
            movementModes = [MovementMode.inVehicle.rawValue as NSNumber: 50]
        } else {
            movementModes = [MovementMode.unknown.rawValue as NSNumber: 50]
        }
        return MovementInfo(movementMode: movementModes, movementProvider: .SDK)
    }
}

extension ProfileIdentifier {
    var movementMode: MovementMode? {
        switch self {
        case .automobile, .automobileAvoidingTraffic:
            return .inVehicle
        case .cycling:
            return .cycling
        case .walking:
            return .onFoot
        default:
            return nil
        }
    }
}
