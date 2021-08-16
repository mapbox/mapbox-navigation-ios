import MapboxDirections
import MapboxNavigationNative

protocol CacheHandlerData {
    var tileStorePath: String { get }
    var credentials: DirectionsCredentials { get }
    var tilesVersion: String? { get }
    var historyDirectoryURL: URL? { get }
    var targetVersion: String? { get }
    var configFactoryType: ConfigFactory.Type { get }
}

extension NativeHandlersFactory: CacheHandlerData { }

enum CacheHandlerFactory {
    
    private struct CacheKey: CacheHandlerData {
        let tileStorePath: String
        let credentials: DirectionsCredentials
        let tilesVersion: String?
        let historyDirectoryURL: URL?
        let targetVersion: String?
        let configFactoryType: ConfigFactory.Type
        
        init(data: CacheHandlerData) {
            self.tileStorePath = data.tileStorePath
            self.credentials = data.credentials
            self.tilesVersion = data.tilesVersion
            self.historyDirectoryURL = data.historyDirectoryURL
            self.targetVersion = data.targetVersion
            self.configFactoryType = data.configFactoryType
        }
        
        static func != (lhs: CacheKey, rhs: CacheHandlerData) -> Bool {
            return lhs.tileStorePath != rhs.tileStorePath ||
                lhs.credentials != rhs.credentials ||
                lhs.tilesVersion != rhs.tilesVersion ||
                lhs.historyDirectoryURL != rhs.historyDirectoryURL ||
                lhs.targetVersion != rhs.targetVersion ||
                lhs.configFactoryType != rhs.configFactoryType
        }
    }
    
    private static var key: CacheKey? = nil
    private static var cachedHandle: CacheHandle!
    private static let lock = NSLock()
    
    static func getHandler(for tilesConfig: TilesConfig,
                           config: ConfigHandle,
                           historyRecorder: HistoryRecorderHandle?,
                           cacheData: CacheHandlerData) -> CacheHandle {
        lock.lock(); defer {
            lock.unlock()
        }
        
        if key == nil || key! != cacheData {
            cachedHandle = CacheFactory.build(for: tilesConfig,
                                              config: config,
                                              historyRecorder: historyRecorder)
            key = .init(data: cacheData)
        }
        return cachedHandle
    }
}
