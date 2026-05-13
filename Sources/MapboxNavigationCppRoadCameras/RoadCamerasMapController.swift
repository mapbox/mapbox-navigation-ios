import Combine
import Foundation
import MapboxCoreMaps
internal import MapboxCoreMaps_Private
internal import MapboxNavSdk
internal import MapboxNavSdkMapComponents
@_spi(Internal) import MapboxMaps
@_spi(Internal) @_spi(Marshalling) import MapboxCoreMaps.Map

/// Manager that renders the road cameras on the map.
@_spi(ExperimentalMapboxAPI)
@MainActor
public final class RoadCamerasMapController {
    private let native: MapboxNavSdk.RoadCamerasMapController

    /// Creates an instance of a manager.
    /// - Parameters:
    ///    - map: ``MapView.mapboxMap`` instance.
    ///    - manager: Road cameras data manager.
    ///    - config: Road cameras rendering configuration.
    public init(
        map: MapboxMap,
        manager: RoadCamerasManager,
        config: RoadCamerasConfig
    ) {
        let coreMap: MapboxCoreMaps_Private.Map = MapboxCoreMaps.Map.Marshaller.toObjc(map.map)
        self.native = MapboxNavSdk.RoadCamerasMapController(
            map: coreMap,
            manager: manager.native,
            config: config.native
        )
    }

    // MARK: - Properties

    /// Controls the visibility of road cameras markers.
    ///
    /// Once set to `false`, all current road cameras markers will be hidden.
    /// Once set to `true`, the latest available cameras will be shown on the map.
    public var isVisible: Bool {
        get { native.getIsVisible() }
        set { native.setIsVisibleForVisible(newValue) }
    }

    // MARK: - Publishers

    /// Emitted when `isVisible` changes.
    public var isVisibleChanged: AnyPublisher<Bool, Never> {
        publisher { [native] callback in native.registerIsVisibleChangedSignal(callback) }
    }

    /// Emitted when the configuration has changed.
    public var configChanged: AnyPublisher<Void, Never> {
        publisher { [native] callback in native.registerConfigChangedSignal(callback) }
    }

    /// Emitted when a road camera marker is clicked.
    public var cameraClicked: AnyPublisher<RoadCamera, Never> {
        publisher { [native] callback in
            native.registerCameraClickedSignal { camera in
                callback(RoadCamera(camera))
            }
        }
    }

    /// Emitted initially when cameras appear on the map and on each subsequent update.
    public var camerasAppearing: AnyPublisher<[RoadCamera], Never> {
        publisher { [native] callback in
            native.registerCamerasAppearingSignal { cameras in
                callback(cameras.map(RoadCamera.init))
            }
        }
    }

    /// Emitted when cameras have been passed and are now behind the car.
    public var camerasPassed: AnyPublisher<[RoadCamera], Never> {
        publisher { [native] callback in
            native.registerCamerasPassedSignal { cameras in
                callback(cameras.map(RoadCamera.init))
            }
        }
    }

    /// Emitted when cameras are hidden due to configuration, visibility, or route changes.
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

    /// Sets the configuration for the road cameras. Config can be changed dynamically.
    public func setConfig(_ config: RoadCamerasConfig) {
        native.setConfigFor(config.native)
    }
}
