
import Foundation
import MapboxCommon

/**
 To add docs for cases
 */
public enum TileStoreLocation {
    public enum Strict {
        case `default`
        case custom(URL)
        
        public var tilStoreURL: URL? {
            switch self {
            case .default:
                return nil
            case .custom(let url):
                return url
            }
        }
    }
    public enum Optional {
        case `default`
        case custom(URL)
        case noStorage
        
        public var tileStore: TileStore? {
            switch self {
            case .default:
                return TileStore.getInstance()
            case .noStorage:
                return nil
            case .custom(let url):
                return TileStore.getInstanceForPath(url.path)
            }
        }
    }
    
    case `default`
    case custom(URL)
    case isolated(navigationLocation: Strict, mapLocation: Optional)
    
    public var navigatorTileStoreLocation: Strict {
        switch self {
        case .default:
            return .default
        case .custom(let url):
            return .custom(url)
        case .isolated(let navLocation, _):
            return navLocation
        }
    }
    
    public var mapTileStoreLocation: Optional {
        switch self {
        case .default:
            return .default
        case .custom(let url):
            return .custom(url)
        case .isolated(_, let mapLocation):
            return mapLocation
        }
    }
}
