import Foundation
import MapboxNavigationNative
import MapboxDirections

/// A container class for retaining `Navigator` instance.
///
/// Tupically obtained via `NavigatorProvider.sharedWeakNavigator()` for storing and/or configuring shared `Navigator`.
public final class NavigatorWithHistory {
    let navigator: Navigator
    let history: HistoryRecorderHandle
    
    init(navigator: Navigator, history: HistoryRecorderHandle) {
        self.navigator = navigator
        self.history = history
    }
}

/// A fabric, used for obtaining and/or configuring `Navigator`.
public class NavigatorProvider {
    private init() {}
    
    static public let defaultVersion = ""
    static private let internalQueue: DispatchQueue = DispatchQueue(label:"com.mapbox.coreNavigation.NavigatorProvider.internalQueue")
    static private weak var _sharedNavigatorWithHistory: NavigatorWithHistory?
    
    /// Provides a new or an existing one `Navigator` instance along with related `HistoryRecorderHandle`, satisfying provided configuration.
    ///
    /// This method returns a `weak` reference. You should retain it yourself as long as you need.
    /// `NavigatorProvider` does not retain 'shared' instances itself but only initializes and allows acces to it.
    ///
    /// - parameter tilesVersion: Tiles version name string. If not specified explicitly - will be automatically resolved to the latest one
    /// - parameter tilesURL: A local path to the tiles storage location. If not supplied - will be automatically defaulted to the cache subdirectory.
    /// - returns: A pair of `Navigator` and corresponding `HistoryRecorderHandle` instance. User is responsible for ownership of this instance.
    static public func sharedWeakNavigator(tilesVersion: String = defaultVersion,
                                           tilesURL: URL? = nil) -> NavigatorWithHistory {
        var navigator: NavigatorWithHistory!
        internalQueue.sync {
            if let sharedNavigator = _sharedNavigatorWithHistory {
                navigator = sharedNavigator
            } else {
                var tilesPath: String! = tilesURL?.path
                if tilesPath == nil {
                    let bundle = Bundle.mapboxCoreNavigation
                    if bundle.ensureSuggestedTileURLExists() {
                        tilesPath = bundle.suggestedTileURL!.path
                    } else {
                        preconditionFailure("Could not access cache storage")
                    }
                }
                
                let settingsProfile = SettingsProfile(application: ProfileApplication.kMobile, platform: ProfilePlatform.KIOS)
                
                let endpointConfig = TileEndpointConfiguration(directions: Directions.shared,
                                                               tilesVersion: tilesVersion)
                let navigatorTilesConfig = TilesConfig(tilesPath: tilesPath,
                                                       inMemoryTileCache: nil,
                                                       onDiskTileCache: nil,
                                                       mapMatchingSpatialCache: nil,
                                                       threadsCount: nil,
                                                       endpointConfig: endpointConfig)
                
                let configFactory = try! ConfigFactory.build(for: settingsProfile,
                                                             config: NavigatorConfig(),
                                                             customConfig: "")
                let historyRecorder = try! HistoryRecorderHandle.build(forConfig: configFactory)
                let runloopExecutor = try! RunLoopExecutorFactory.build()
                let cacheHandle = try! CacheFactory.build(for: navigatorTilesConfig,
                                                          config: configFactory,
                                                          runLoop: runloopExecutor,
                                                          historyRecorder: historyRecorder)
                
                navigator = NavigatorWithHistory(navigator: try! Navigator(config: configFactory,
                                                                           runLoopExecutor: runloopExecutor,
                                                                           cache: cacheHandle,
                                                                           historyRecorder: historyRecorder),
                                                 history: historyRecorder)
                print(tilesPath)
                _sharedNavigatorWithHistory = navigator
            }
        }
        return navigator
    }
    
    /// Check if navigator is currently used in system.
    ///
    /// - returns: `True` if `Navigator` instance exists and is retained by some other entity. `False` - otherwise
    static public func navigatorIsActive() -> Bool {
        var isActive = false
        internalQueue.sync {
            isActive = _sharedNavigatorWithHistory != nil
        }
        return isActive
    }
}
