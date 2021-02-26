import Foundation
import MapboxNavigationNative
import MapboxDirections

extension Navigator {
    
    /**
     Tiles version string. If not specified explicitly - will be automatically resolved
     to the latest version.
     
     This property can only be modified before creating `Navigator` shared instance, all
     further changes to this property will have no effect.
     */
    static var tilesVersion: String = ""
    
    /**
     A local path to the tiles storage location. If not specified - will be automatically defaulted
     to the cache subdirectory.
     
     This property can only be modified before creating `Navigator` shared instance, all
     further changes to this property will have no effect.
     */
    static var tilesURL: URL? = nil
    
    /**
     Shared instance on `Navigator`.
     */
    static let shared: Navigator = {
        return navigatorWithHistoryRecorder.0
    }()
    
    static func enableHistoryRecorder() throws {
        try historyRecorder.enable(forEnabled: true)
    }
    
    static func disableHistoryRecorder() throws {
        try historyRecorder.enable(forEnabled: false)
    }
    
    static func history() throws -> Data {
        return try historyRecorder.getHistory()
    }
    
    private static var historyRecorder: HistoryRecorderHandle = {
        return navigatorWithHistoryRecorder.1
    }()
    
    private static let internalQueue = DispatchQueue(label: "com.mapbox.coreNavigation.navigator.internalQueue")
    
    /**
     Provides a new or an existing one `Navigator` instance along with related `HistoryRecorderHandle`,
     satisfying provided configuration (`tilesVersion` and `tilesURL`).
     */
    private static let navigatorWithHistoryRecorder: (Navigator, HistoryRecorderHandle) = {
        var navigator: Navigator!
        var historyRecorder: HistoryRecorderHandle!
        internalQueue.sync {
            if let sharedNavigator = navigator, let sharedHistoryRecorder = historyRecorder {
                navigator = sharedNavigator
                historyRecorder = sharedHistoryRecorder
            } else {
                var tilesPath: String! = tilesURL?.path
                if tilesPath == nil {
                    let bundle = Bundle.mapboxCoreNavigation
                    if bundle.ensureSuggestedTileURLExists() {
                        tilesPath = bundle.suggestedTileURL!.path
                    } else {
                        preconditionFailure("Failed to access cache storage.")
                    }
                }
                
                let settingsProfile = SettingsProfile(application: ProfileApplication.kMobile,
                                                      platform: ProfilePlatform.KIOS)
                
                let endpointConfig = TileEndpointConfiguration(credentials: Directions.shared.credentials,
                                                               tilesVersion: tilesVersion,
                                                               minimumDaysToPersistVersion: nil)
                
                let tilesConfig = TilesConfig(tilesPath: tilesPath,
                                              inMemoryTileCache: nil,
                                              onDiskTileCache: nil,
                                              mapMatchingSpatialCache: nil,
                                              threadsCount: nil,
                                              endpointConfig: endpointConfig)
                
                let configFactory = try! ConfigFactory.build(for: settingsProfile,
                                                             config: NavigatorConfig(),
                                                             customConfig: "")
                
                historyRecorder = try! HistoryRecorderHandle.build(forConfig: configFactory)
                
                let runloopExecutor = try! RunLoopExecutorFactory.build()
                let cacheHandle = try! CacheFactory.build(for: tilesConfig,
                                                          config: configFactory,
                                                          runLoop: runloopExecutor,
                                                          historyRecorder: historyRecorder)
                
                navigator = try! Navigator(config: configFactory,
                                           runLoopExecutor: runloopExecutor,
                                           cache: cacheHandle,
                                           historyRecorder: historyRecorder)
            }
        }
        
        return (navigator, historyRecorder)
    }()
    
    func status(at timestamp: Date) -> NavigationStatus {
        return try! getStatusForMonotonicTimestampNanoseconds(
            Int64(timestamp.nanosecondsSince1970)
        )
    }
}
