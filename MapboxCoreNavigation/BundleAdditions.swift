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
    
    var locationAlwaysUsageDescription: String? {
        get {
            return object(forInfoDictionaryKey: "NSLocationAlwaysUsageDescription") as? String
        }
    }
    
    /**
     The Mapbox Core Navigation framework bundle.
     */
    @objc public class var mapboxCoreNavigation: Bundle {
        return Bundle(for: RouteController.self)
    }
    
    public func ensureSuggestedTileURLExists() -> Bool {
        guard let tilePath = suggestedTileURL else { return false }
        try? FileManager.default.createDirectory(at: tilePath, withIntermediateDirectories: true, attributes: nil)
        return true
    }
    
    /**
     A file URL representing a directory in which the application can place downloaded tile files.
     */
    @objc public var suggestedTileURL: URL? {
        
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
    @objc(suggestedTileURLWithVersion:)
    public func suggestedTileURL(version: String) -> URL? {
        return suggestedTileURL?.appendingPathComponent(version)
    }
}
