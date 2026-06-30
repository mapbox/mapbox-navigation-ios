import Combine
import Foundation
import MapboxNavigationNative
internal import MapboxNavigationNative_Private
internal import MapboxNavSdk
internal import MapboxNavSdk_Private
internal import MapboxNavSdkNavigation
internal import MapboxNavSdkNavigation_Private

/// Manager that monitors and manages road cameras withing the active navigation activity.
@_spi(ExperimentalMapboxAPI)
@MainActor
public final class RoadCamerasManager {
    private let navigator: MapboxNavSdkNavigation.Navigator
    let native: MapboxNavSdk.RoadCamerasManager

    /// Creates an instance of a manager.
    /// - Parameters:
    ///    - navigator: ``MapboxNavigationProvider.nativeNavigator`` internal navigator instance.
    public init?(navigator: Any) {
        guard let nativeNavigator = navigator as? MapboxNavigationNative.Navigator else {
            return nil
        }
        self.navigator = MapboxNavSdkNavigation.Navigator(
            internalNavigator: nativeNavigator,
            historyRecorder: nil
        )
        self.native = MapboxNavSdk.RoadCamerasManager(navigator: self.navigator)
    }

    /// Enable monitoring of road cameras.
    public var isEnabled: Bool {
        get { native.getIsEnabled() }
        set { native.setIsEnabledForEnabled(newValue) }
    }

    // MARK: - Publishers

    /// Emitted when `isEnabled` changes.
    public var isEnabledChanged: AnyPublisher<Bool, Never> {
        publisher { [native] callback in native.registerIsEnabledChangedSignal(callback) }
    }

    /// Emitted every time distances to cameras are updated when cameras are approaching.
    public var camerasAppearing: AnyPublisher<[RoadCamera], Never> {
        publisher { [native] callback in
            native.registerCamerasAppearingSignal { cameras in
                callback(cameras.map(RoadCamera.init))
            }
        }
    }

    /// Emitted when road cameras have been passed.
    public var camerasPassed: AnyPublisher<[RoadCamera], Never> {
        publisher { [native] callback in
            native.registerCamerasPassedSignal { cameras in
                callback(cameras.map(RoadCamera.init))
            }
        }
    }

    /// Emitted when cameras must be hidden.
    public var camerasHidden: AnyPublisher<[RoadCamera], Never> {
        publisher { [native] callback in
            native.registerCamerasHiddenSignal { cameras in
                callback(cameras.map(RoadCamera.init))
            }
        }
    }

    /// Emitted when the vehicle enters and moves through a speed zone.
    public var speedZoneProgress: AnyPublisher<SpeedZoneInfo, Never> {
        publisher { [native] callback in
            native.registerSpeedZoneProgressSignal { info in
                callback(SpeedZoneInfo(info))
            }
        }
    }

    /// Emitted when the vehicle has exited a speed zone.
    public var speedZoneExited: AnyPublisher<SpeedZoneInfo, Never> {
        publisher { [native] callback in
            native.registerSpeedZoneExitedSignal { info in
                callback(SpeedZoneInfo(info))
            }
        }
    }
}
