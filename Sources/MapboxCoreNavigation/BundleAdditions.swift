import Foundation

extension Bundle {
    /**
     Returns a set of strings containing supported background mode types.
     */
    public var backgroundModes: Set<String> {
        if let modes = object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] {
            return Set<String>(modes)
        }
        return []
    }
    
    var locationAlwaysAndWhenInUseUsageDescription: String? {
        get {
            return object(forInfoDictionaryKey: "NSLocationAlwaysAndWhenInUseUsageDescription") as? String
        }
    }
    
    var locationWhenInUseUsageDescription: String? {
        get {
            return object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") as? String
        }
    }
    
    /**
     The Mapbox Core Navigation framework bundle.
     */
    public class var mapboxCoreNavigation: Bundle {
        get {
            #if SWIFT_PACKAGE
            return .module
            #else
            return Bundle(for: RouteController.self)
            #endif
        }
    }
    
    /**
     The Mapbox Navigation framework bundle, if installed.
     */
    class var mapboxNavigationIfInstalled: Bundle? {
        get {
            #if SWIFT_PACKAGE
            for bundleIdentifier in Bundle.allBundles.compactMap({ $0.bundleIdentifier }) {
                if bundleIdentifier.contains("MapboxNavigation-MapboxNavigation") {
                    return Bundle(identifier: bundleIdentifier)
                }
            }
            return nil
            #else
            // Assumption: MapboxNavigation.framework includes NavigationViewController and exposes it to the Objective-C runtime as MapboxNavigation.NavigationViewController.
            guard let NavigationViewController = NSClassFromString("MapboxNavigation.NavigationViewController") else { return nil }
            return Bundle(for: NavigationViewController)
            #endif
        }
    }
    
    public func ensureSuggestedTileURLExists() -> Bool {
        guard let tilePath = suggestedTileURL else { return false }
        try? FileManager.default.createDirectory(at: tilePath, withIntermediateDirectories: true, attributes: nil)
        return true
    }
    
    /**
     Returns a dictionary of `MBXInfo.plist` in Mapbox Core Navigation.
     */
    static let mapboxCoreNavigationInfoDictionary: [String: Any]? = {
        guard let fileURL = Bundle.mapboxCoreNavigation.url(forResource: "MBXInfo", withExtension: "plist"),
              let infoDictionary = NSDictionary(contentsOf: fileURL) as? [String: Any] else { return nil }
        return infoDictionary
    }()
    
    /**
     Returns a dictionary of `MBXInfo.plist` in Mapbox Navigation framework bundle, if installed.
     */
    static let mapboxNavigationInfoDictionary: [String: Any]? = {
        guard let fileURL = Bundle.mapboxNavigationIfInstalled?.url(forResource: "MBXInfo", withExtension: "plist"),
              let infoDictionary = NSDictionary(contentsOf: fileURL) as? [String: Any] else { return nil }
        return infoDictionary
    }()
    
    /**
     Returns the value associated with the specific key in the Mapbox Navigation bundle's  information property list, if installed.
     */
    public class func string(forMapboxNavigationInfoDictionaryKey key: String) -> String? {
        if let stringForKey = Bundle.mapboxNavigationIfInstalled?.object(forInfoDictionaryKey: key) {
            return stringForKey as? String
        } else if let infoDictionary = Bundle.mapboxNavigationInfoDictionary {
            return infoDictionary[key] as? String
        } else {
            return nil
        }
    }
    
    /**
     Returns the value associated with the specific key in the Mapbox Core Navigation bundle's  information property list.
     */
    public class func string(forMapboxCoreNavigationInfoDictionaryKey key: String) -> String? {
        if let stringForKey = Bundle.mapboxCoreNavigation.object(forInfoDictionaryKey: key) {
            return stringForKey as? String
        } else if let infoDictionary = Bundle.mapboxCoreNavigationInfoDictionary {
            return infoDictionary[key] as? String
        } else {
            return nil
        }
    }
    
    /**
     A file URL representing a directory in which the application can place downloaded tile files.
     */
    public var suggestedTileURL: URL? {
        guard let cachesDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            return nil
        }
        
        guard let bundleIdentifier = self.bundleIdentifier else { return nil }
        let url = URL(fileURLWithPath: cachesDirectory, isDirectory: true).appendingPathComponent(bundleIdentifier)
        
        return url.appendingPathComponent("tiles")
    }
    
    /**
     A file URL at which the application can place a downloaded tile file with the given version identifier.
     */
    public func suggestedTileURL(version: String) -> URL? {
        return suggestedTileURL?.appendingPathComponent(version)
    }
}
