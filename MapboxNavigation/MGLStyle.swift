import Foundation
import Mapbox


extension MGLStyle {
    
    // The Mapbox China Day Style URL.
    static let mapboxChinaDayStyleURL = URL(string:"mapbox://styles/mapbox/streets-zh-v1")!
    
    // The Mapbox China Night Style URL.
    static let mapboxChinaNightStyleURL = URL(string:"mapbox://styles/mapbox/dark-zh-v1")!
    
    /**
     Returns the URL to the current version of the Mapbox Navigation Guidance Day style.
     */
    @objc public class var navigationGuidanceDayStyleURL: URL {
        get {
            if(MGLAccountManager.hasChinaBaseURL){
                return mapboxChinaDayStyleURL
            }
            return URL(string:"mapbox://styles/mapbox/navigation-guidance-day-v4")!
        }
    }
    
    /**
     Returns the URL to the current version of the Mapbox Navigation Guidance Night style.
     */
    @objc public class var navigationGuidanceNightStyleURL: URL {
        get {
            if(MGLAccountManager.hasChinaBaseURL){
                return mapboxChinaDayStyleURL
            }
            return URL(string:"mapbox://styles/mapbox/navigation-guidance-night-v4")!
        }
    }
    
    /**
     Returns the URL to the given version of the navigation guidance style. Available version are 1, 2, 3, and 4.
     
     We only have one version of navigation guidance style in China, so if you switch your endpoint to .cn, it will return the default day style.
     */
    @objc public class func navigationGuidanceDayStyleURL(version: Int) -> URL {
        if(MGLAccountManager.hasChinaBaseURL){
            return mapboxChinaDayStyleURL
        }
        return URL(string:"mapbox://styles/mapbox/navigation-guidance-day-v\(version)")!
    }
    
    
    /**
     Returns the URL to the given version of the navigation guidance style. Available version are 2, 3, and 4.
     
     We only have one version of navigation guidance style in China, so if you switch your endpoint to .cn, it will return the default night style.
     */
    @objc public class func navigationGuidanceNightStyleURL(version: Int) -> URL {
        if(MGLAccountManager.hasChinaBaseURL){
            return mapboxChinaNightStyleURL
        }
        return URL(string: "mapbox://styles/mapbox/navigation-guidance-night-v\(version)")!
    }
    
    /**
     Returns the URL to the current version of the Mapbox Navigation Preview Day style.
     */
    @objc public class var navigationPreviewDayStyleURL: URL {
        get {
            if MGLAccountManager.hasChinaBaseURL {
                return mapboxChinaDayStyleURL
            }
            return URL(string:"mapbox://styles/mapbox/navigation-preview-day-v4")!
        }
    }
    
    /**
     Returns the URL to the current version of the Mapbox Navigation Preview Night style.
     */
    @objc public class var navigationPreviewNightStyleURL: URL {
        get {
            if MGLAccountManager.hasChinaBaseURL {
                return mapboxChinaDayStyleURL
            }
            return URL(string:"mapbox://styles/mapbox/navigation-preview-night-v4")!
        }
    }
    
    /**
     Returns the URL to the given version of the Mapbox Navigation Preview Day style. Available versions are 1, 2, 3, and 4.
     
     We only have one version of Navigation Preview style in China, so if you switch your endpoint to .cn, it will return the default day style.
     */
    @objc public class func navigationPreviewDayStyleURL(version: Int) -> URL {
        if MGLAccountManager.hasChinaBaseURL {
            return mapboxChinaDayStyleURL
        }
        return URL(string:"mapbox://styles/mapbox/navigation-guidance-day-v\(version)")!
    }
    
    
    /**
     Returns the URL to the given version of the Mapbox Navigation Preview Night style. Available versions are 2, 3, and 4.
     
     We only have one version of Navigation Preview style in China, so if you switch your endpoint to .cn, it will return the default night style.
     */
    @objc public class func navigationPreviewNightStyleURL(version: Int) -> URL {
        if MGLAccountManager.hasChinaBaseURL {
            return mapboxChinaNightStyleURL
        }
        return URL(string: "mapbox://styles/mapbox/navigation-guidance-night-v\(version)")!
    }
}
