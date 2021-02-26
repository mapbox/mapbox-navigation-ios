import Foundation
import MapboxNavigationNative
import MapboxDirections

extension Navigator {
    
    static var tilesVersion: String = ""
    
    static var tilesURL: URL? = nil
    
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
    
    static private let internalQueue = DispatchQueue(label: "com.mapbox.coreNavigation.Navigator.internalQueue")
    
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
