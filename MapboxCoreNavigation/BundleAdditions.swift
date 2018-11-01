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
    
    public class var mapboxCoreNavigation: Bundle {
        get { return Bundle(for: RouteController.self) }
    }
    
    public func ensureSuggestedTilePathExists() -> Bool {
        guard let tilePath = suggestedTilePath else { return false }
        try? FileManager.default.createDirectory(at: tilePath, withIntermediateDirectories: true, attributes: nil)
        return true
    }
    
    public var suggestedTilePath: URL? {
        
        guard let cachesDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            return nil
        }
        
        guard let bundleIdentifier = self.bundleIdentifier else { return nil }
        let path = URL(fileURLWithPath: cachesDirectory, isDirectory: true).appendingPathComponent(bundleIdentifier)
        
        return path.appendingPathComponent("tiles")
    }
    
    public func suggestedTilePath(for version: String) -> URL? {
        return suggestedTilePath?.appendingPathComponent(version)
    }
}
