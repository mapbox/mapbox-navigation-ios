import Foundation
import MapboxCommon

/**
 Options for configuring how map and navigation tiles are stored on the device.
 
 This struct encapsulates logic for handling `default` and `custom` paths as well as providing corresponding `TileStore`s.
 It also covers differences between tile storages for Map and Navigation data. Tupically, you won't need to configure these and rely on defaults, unless you provide pre-downloaded data withing your app in which case you'll need `custom()` path to point to your data.
 */
public struct TileStoreConfiguration {
    /**
     Describes filesystem location for tile storage folder
     */
    public enum Location {
        /**
         Encapsulated default location.
         
         `rawValue` for this case will return `nil`
         */
        case `default`
        /**
         User-provided path to tile storage folder
         */
        case custom(URL)
        
        /**
         Corresponding URL path
         
         `default` location is interpreted as `nil`.
         */
        public var tileStoreURL: URL? {
            switch self {
            case .default:
                return nil
            case .custom(let url):
                return url
            }
        }
        /**
         A `TileStore` instance, configured for current location.
         */
        public var tileStore: TileStore {
            switch self {
            case .default:
                return TileStore.__create()
            case .custom(let url):
                return TileStore.__create(forPath: url.path)
            }
        }
    }
    
    /**
     Location of Navigator tiles data
     */
    public let navigatorLocation: Location
    /**
     Location of Map tiles data
     */
    public let mapLocation: Location?
    
    /**
     Tile data will be stored at default SDK location
     */
    public static var `default`: Self {
        .init(navigatorLocation: .default, mapLocation: .default)
    }
    /**
     Custom path to a folder, where tiles data will be stored
     */
    public static func custom(_ url: URL) -> Self {
        .init(navigatorLocation: .custom(url), mapLocation: .custom(url))
    }
    /**
     :nodoc:
     
     Option to configure Map and Navigation tiles to be stored separately. You should not use this option unless you know what you are doing.
     */
    public static func isolated(navigationLocation: Location, mapLocation: Location?) -> Self {
        .init(navigatorLocation: navigationLocation, mapLocation: mapLocation)
    }
}
