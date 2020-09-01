import Foundation
import Mapbox

extension MGLStyle {
    // The Mapbox China Day Style URL.
    static let mapboxChinaDayStyleURL = URL(string:"mapbox://styles/mapbox/streets-zh-v1")!
    
    // The Mapbox China Night Style URL.
    static let mapboxChinaNightStyleURL = URL(string:"mapbox://styles/mapbox/dark-zh-v1")!
    
    // Default Mapbox Navigation Day Style URL.
    static let defaultNavigationDayStyleURL = URL(string:"mapbox://styles/mapbox/navigation-day-v1")!
    
    // Default Mapbox Navigation Night Style URL.
    static let defaultNavigationNightStyleURL = URL(string:"mapbox://styles/mapbox/navigation-night-v1")!
    
    /**
     Returns the URL to the current version of the Mapbox Navigation Day style.
     */
    public class var navigationDayStyleURL: URL {
        get {
            if MGLAccountManager.hasChinaBaseURL {
                return mapboxChinaDayStyleURL
            }
            return defaultNavigationDayStyleURL
        }
    }
    
    /**
     Returns the URL to the current version of the Mapbox Navigation Night style.
     */
    public class var navigationNightStyleURL: URL {
        get {
            if MGLAccountManager.hasChinaBaseURL {
                return mapboxChinaNightStyleURL
            }
            return defaultNavigationNightStyleURL
        }
    }
    
    /**
     Returns the URL to the given version of the Mapbox Navigation Day style. Available versions are 1, 2, 3, 4 and 5.
     
     We only have one version of Mapbox Navigation Day style in China, so if you switch your endpoint to .cn, it will return the default day style.
     */
    public class func navigationDayStyleURL(version: Int) -> URL {
        if MGLAccountManager.hasChinaBaseURL {
            return mapboxChinaDayStyleURL
        }
        
        if (1...4).contains(version) {
            return URL(string:"mapbox://styles/mapbox/navigation-guidance-day-v\(version)")!
        }
        
        return defaultNavigationDayStyleURL
    }
    
    /**
     Returns the URL to the given version of the Mapbox Navigation Night style. Available versions are 2, 3, 4 and 5.
     
     We only have one version of Mapbox Navigation Night style in China, so if you switch your endpoint to .cn, it will return the default night style.
     */
    public class func navigationNightStyleURL(version: Int) -> URL {
        if MGLAccountManager.hasChinaBaseURL {
            return mapboxChinaNightStyleURL
        }
        
        if (2...4).contains(version) {
            return URL(string:"mapbox://styles/mapbox/navigation-guidance-night-v\(version)")!
        }
        
        return defaultNavigationNightStyleURL
    }
    
    /**
     Remove the given style layers from the style in order.
     */
    func remove(_ layers: [MGLStyleLayer]) {
        for layer in layers {
            removeLayer(layer)
        }
    }
    
    /**
     Remove the given sources from the style.
     
     Only remove a source after removing all the style layers that use it.
     */
    func remove(_ sources: Set<MGLSource>) {
        for source in sources {
            removeSource(source)
        }
    }
}
