import MapboxNavigationNative
import MapboxDirections

class Navigator {
    
    /**
     Tiles version string. If not specified explicitly - will be automatically resolved
     to the latest version.
     
     This property can only be modified before creating `Navigator` shared instance, all
     further changes to this property will have no effect.
     */
    static var tilesVersion: String = ""
    
    /**
     A local path to the tiles storage location. If not specified - will be automatically set to a default location.
     
     This property can only be modified before creating `Navigator` shared instance, all
     further changes to this property will have no effect. After initialisation, use `tileStore` to get correponding instance.
     */
    static var tilesURL: URL? = nil
    
    /**
     Path to the directory where history file could be stored when `Navigator.writeHistory(completionHandler:)` is called.
     */
    static var historyDirectoryURL: URL? = nil
    
    /**
     Store history to the directory stored in `Navigator.historyDirectoryURL` and asynchronously run a callback
     when writing finishes.
     
     - parameter completionHandler: A block object to be executed when history dumping ends.
     */
    func writeHistory(completionHandler: @escaping (URL?) -> Void) {
        historyRecorder.dumpHistory { (path) in
            if let path = path {
                completionHandler(URL(fileURLWithPath: path))
            } else {
                completionHandler(nil)
            }
        }
    }
    
    private(set) var historyRecorder: HistoryRecorderHandle
    
    private(set) var navigator: MapboxNavigationNative.Navigator
    
    private(set) var cacheHandle: CacheHandle
    
    private(set) var roadGraph: RoadGraph
    
    lazy var roadObjectStore: RoadObjectStore = {
        return RoadObjectStore(navigator.roadObjectStore())
    }()
    
    lazy var roadObjectMatcher: RoadObjectMatcher = {
        return RoadObjectMatcher(MapboxNavigationNative.RoadObjectMatcher(cache: cacheHandle))
    }()
    
    lazy var router: MapboxNavigationNative.Router = {
        return MapboxNavigationNative.Router(cache: cacheHandle,
                                             historyRecorder: historyRecorder)
    }()


    private(set) var tileStore: TileStore
    
    /**
     The Authorization & Authentication credentials that are used for this service. If not specified - will be automatically intialized from the token and host from your app's `info.plist`.
     
     - precondition: `credentials` should be set before getting the shared navigator for the first time.
     */
    static var credentials: DirectionsCredentials? = nil
    
    /**
     Provides a new or an existing `MapboxCoreNavigation.Navigator` instance. Upon first initialization will trigger creation of `MapboxNavigationNative.Navigator` and `HistoryRecorderHandle` instances,
     satisfying provided configuration (`tilesVersion` and `tilesURL`).
     */
    static var shared: Navigator {
        return _navigator
    }
    
    // Used in tests to recreate the navigator
    static var _navigator: Navigator = .init()
    
    static func _recreateNavigator() { _navigator = .init() }
    
    /**
     Restrict direct initializer access.
     */
    private init() {
        let factory = NativeHandlersFactory(tileStorePath: Self.tilesURL?.path ?? "",
                                            credentials: Self.credentials ?? Directions.shared.credentials,
                                            tilesVersion: Self.tilesVersion,
                                            historyDirectoryURL: Self.historyDirectoryURL)
        tileStore = factory.tileStore
        historyRecorder = factory.historyRecorder
        cacheHandle = factory.cacheHandle
        roadGraph = factory.roadGraph
        navigator = factory.navigator
        
        subscribeNavigator()
    }
    
    private func subscribeNavigator() {
        navigator.setElectronicHorizonObserverFor(self)
        navigator.addObserver(for: self)
    }
    
    private func unsubscribeNavigator() {
        navigator.setElectronicHorizonObserverFor(nil)
    }
    
    deinit {
        unsubscribeNavigator()
    }
    
    var electronicHorizonOptions: ElectronicHorizonOptions? {
        didSet {
            let nativeOptions: MapboxNavigationNative.ElectronicHorizonOptions?
            if let electronicHorizonOptions = electronicHorizonOptions {
                nativeOptions = MapboxNavigationNative.ElectronicHorizonOptions(electronicHorizonOptions)
            } else {
                nativeOptions = nil
            }
            navigator.setElectronicHorizonOptionsFor(nativeOptions)
        }
    }
}

extension Navigator: ElectronicHorizonObserver {
    public func onPositionUpdated(for position: ElectronicHorizonPosition, distances: [MapboxNavigationNative.RoadObjectDistance]) {
        let userInfo: [RoadGraph.NotificationUserInfoKey: Any] = [
            .positionKey: RoadGraph.Position(position.position()),
            .treeKey: RoadGraph.Edge(position.tree().start),
            .updatesMostProbablePathKey: position.type() == .update,
            .distancesByRoadObjectKey: distances.map(DistancedRoadObject.init),
        ]
        NotificationCenter.default.post(name: .electronicHorizonDidUpdatePosition, object: nil, userInfo: userInfo)
    }
    
    public func onRoadObjectEnter(for info: RoadObjectEnterExitInfo) {
        let userInfo: [RoadGraph.NotificationUserInfoKey: Any] = [
            .roadObjectIdentifierKey: info.roadObjectId,
            .didTransitionAtEndpointKey: info.isEnterFromStartOrExitFromEnd,
        ]
        NotificationCenter.default.post(name: .electronicHorizonDidEnterRoadObject, object: nil, userInfo: userInfo)
    }
    
    public func onRoadObjectExit(for info: RoadObjectEnterExitInfo) {
        let userInfo: [RoadGraph.NotificationUserInfoKey: Any] = [
            .roadObjectIdentifierKey: info.roadObjectId,
            .didTransitionAtEndpointKey: info.isEnterFromStartOrExitFromEnd,
        ]
        NotificationCenter.default.post(name: .electronicHorizonDidExitRoadObject, object: nil, userInfo: userInfo)
    }

    public func onRoadObjectPassed(for info: RoadObjectPassInfo) {
        let userInfo: [RoadGraph.NotificationUserInfoKey: Any] = [
            .roadObjectIdentifierKey: info.roadObjectId,
        ]
        NotificationCenter.default.post(name: .electronicHorizonDidPassRoadObject, object: nil, userInfo: userInfo)
    }
}

extension Navigator: NavigatorObserver {
    func onStatus(for origin: NavigationStatusOrigin, status: NavigationStatus) {
        guard origin == .locationUpdate else { return }
        let userInfo: [Navigator.NotificationUserInfoKey: Any] = [
            .originKey: origin,
            .statusKey: status,
        ]
        NotificationCenter.default.post(name: .navigationStatusDidChange, object: nil, userInfo: userInfo)
    }
}
extension Notification.Name {
    /**
     Posted when NavNative sends updated navigation status.
     
     The user info dictionary contains the key `MapboxNavigationService.NotificationUserInfoKey.locationAuthorizationKey`.
    */
    static let navigationStatusDidChange: Notification.Name = .init(rawValue: "NavigationStatusDidChange")
}

extension Navigator {
    
    struct NotificationUserInfoKey: Hashable, Equatable, RawRepresentable {
        
        typealias RawValue = String
        
        var rawValue: String
        
        init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        static let originKey: NotificationUserInfoKey = .init(rawValue: "origin")
        
        static let statusKey: NotificationUserInfoKey = .init(rawValue: "status")
    }
}

