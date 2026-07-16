import Combine
import Foundation
import MapboxNavigationNative
internal import MapboxNavigationNative_Private
internal import MapboxNavSdk
internal import MapboxNavSdk_Private

/// Manager that monitors and manages road cameras withing the active navigation activity.
@_spi(ExperimentalMapboxAPI)
@MainActor
public final class RoadCamerasManager {
    let native: MapboxNavSdk.RoadCamerasManager

    /// Creates an instance of a manager.
    /// - Parameters:
    ///    - navigatorHandle: ``MapboxNavigationProvider/navigatorHandle`` shared navigator handle instance.
    public init(navigatorHandle: NavigatorHandle) {
        self.native = MapboxNavSdk.RoadCamerasManager(handle: navigatorHandle)
    }

    /// Creates an instance of a manager.
    ///
    /// - Warning: Deprecated and non-functional. `RoadCamerasManager` is now constructed from a
    /// ``MapboxNavigationProvider/navigatorHandle`` rather than the native navigator. This
    /// initializer always returns `nil`; migrate to ``init(navigatorHandle:)``.
    @available(
        *,
        deprecated,
        message: """
        RoadCamerasManager is now constructed from a NavigatorHandle. \
        Use init(navigatorHandle:) and pass MapboxNavigationProvider.navigatorHandle \
        instead of the native navigator. This initializer always returns nil.
        """
    )
    public init?(navigator: Any) {
        assertionFailure(
            "RoadCamerasManager(navigator:) is deprecated and non-functional. "
                + "Use init(navigatorHandle:) with MapboxNavigationProvider.navigatorHandle."
        )
        return nil
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
