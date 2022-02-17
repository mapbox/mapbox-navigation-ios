import MapboxDirections
import MapboxNavigationNative

protocol HandlerData {
    var tileStorePath: String { get }
    var credentials: Credentials { get }
    var tilesVersion: String { get }
    var historyDirectoryURL: URL? { get }
    var targetVersion: String? { get }
    var configFactoryType: ConfigFactory.Type { get }
    var datasetProfileIdentifier: ProfileIdentifier { get }
}

extension NativeHandlersFactory: HandlerData { }

/**
 :nodoc:
 Creates new or returns existing entity of `HandlerType` constructed with `Arguments`.
 
 This factory is required since some of NavNative's handlers are used by multiple unrelated entities and is quite expensive to allocate. Since bindgen-generated `*Factory` classes are not an actual factory but just a wrapper around general init, `HandlerFactory` introduces basic caching of the latest allocated entity. In most of the cases there should never be multiple handlers with different attributes, so such solution is adequate at the moment.
 */
class HandlerFactory<HandlerType, Arguments> {
    
    private struct CacheKey: HandlerData {
        let tileStorePath: String
        let credentials: Credentials
        let tilesVersion: String
        let historyDirectoryURL: URL?
        let targetVersion: String?
        let configFactoryType: ConfigFactory.Type
        let datasetProfileIdentifier: ProfileIdentifier
        
        init(data: HandlerData) {
            self.tileStorePath = data.tileStorePath
            self.credentials = data.credentials
            self.tilesVersion = data.tilesVersion
            self.historyDirectoryURL = data.historyDirectoryURL
            self.targetVersion = data.targetVersion
            self.configFactoryType = data.configFactoryType
            self.datasetProfileIdentifier = data.datasetProfileIdentifier
        }
        
        static func != (lhs: CacheKey, rhs: HandlerData) -> Bool {
            return lhs.tileStorePath != rhs.tileStorePath ||
                lhs.credentials != rhs.credentials ||
                lhs.tilesVersion != rhs.tilesVersion ||
                lhs.historyDirectoryURL?.absoluteString != rhs.historyDirectoryURL?.absoluteString ||
                lhs.targetVersion != rhs.targetVersion ||
                lhs.configFactoryType != rhs.configFactoryType ||
                lhs.datasetProfileIdentifier != rhs.datasetProfileIdentifier
        }
    }
    
    typealias BuildHandler = (Arguments) -> HandlerType
    let buildHandler: BuildHandler
    
    private var key: CacheKey? = nil
    private var cachedHandle: HandlerType!
    private let lock = NSLock()
    
    fileprivate init(forBuilding buildHandler: @escaping BuildHandler) {
        self.buildHandler = buildHandler
    }
    
    func getHandler(with arguments: Arguments,
                    cacheData: HandlerData) -> HandlerType {
        lock.lock(); defer {
            lock.unlock()
        }
        
        if key == nil || key! != cacheData {
            cachedHandle = buildHandler(arguments)
            key = .init(data: cacheData)
        }
        return cachedHandle
    }
}

let historyRecorderHandlerFactory = HandlerFactory { (path: String,
                                                      configHandle: ConfigHandle) in
    HistoryRecorderHandle.build(forHistoryDir: path,
                                config: configHandle)
}

let cacheHandlerFactory = HandlerFactory { (tilesConfig: TilesConfig,
                                            config: ConfigHandle,
                                            historyRecorder: HistoryRecorderHandle?) in
    CacheFactory.build(for: tilesConfig,
                       config: config,
                       historyRecorder: historyRecorder)
}
