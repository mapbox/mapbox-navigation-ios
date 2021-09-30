import Foundation

extension Bundle {
    
    // MARK: Accessing Mapbox-Specific Bundles
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
     Provides `Bundle` instance, based on provided bundle name and class inside of it.
     
     - parameter `bundleName`: Name of the bundle.
     - parameter `class`: Class, which is located inside of the bundle.
     - returns: Instance of the bundle if it was found, otherwise `nil`.
     */
    static func bundle(for bundleName: String, class: AnyClass) -> Bundle? {
        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,
            
            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: `class`).resourceURL
        ]
        
        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        
        return nil
    }
    
    /**
     The Mapbox Navigation framework bundle, if installed.
     */
    class var mapboxNavigationIfInstalled: Bundle? {
        get {
            // Assumption: MapboxNavigation.framework includes NavigationViewController and exposes
            // it to the Objective-C runtime as MapboxNavigation.NavigationViewController.
            guard let navigationViewControllerClass = NSClassFromString("MapboxNavigation.NavigationViewController") else {
                return nil
            }
            
            #if SWIFT_PACKAGE
            return Bundle.bundle(for: "MapboxNavigation_MapboxNavigation",
                                 class: navigationViewControllerClass)
            #else
            return Bundle(for: navigationViewControllerClass)
            #endif
        }
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
     Returns the value associated with the specific key in the Mapbox Navigation bundle's information property list, if installed.
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
     Returns the value associated with the specific key in the Mapbox Core Navigation bundle's information property list.
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
}
