import Foundation
import Mapbox

extension MGLStyle {
    // Returns the URL to the current version of the Mapbox Navigation Guidance Day style.
    @objc
    public class var navigationGuidanceDayStyleURL: URL { get { return URL(string: "mapbox://styles/mapbox/navigation-guidance-day-v2")! } }
    
    // Returns the URL to the current version of the Mapbox Navigation Guidance Night style.
    @objc
    public class var navigationGuidanceNightStyleURL: URL { get { return URL(string: "mapbox://styles/mapbox/navigation-guidance-night-v2")! } }
    
    @objc
    // Returns the URL to the given version of the navigation guidance style. Available version are 1, 2, and 3.
    public class func navigationGuidanceDayStyleURL(version: Int) -> URL {
        return URL(string: "mapbox://styles/mapbox/navigation-guidance-day-v\(version)")!
    }

    @objc
    // Returns the URL to the given version of the navigation guidance style. Available version are 2, and 3.
    public class func navigationGuidanceNightStyleURL(version: Int) -> URL {
        return URL(string: "mapbox://styles/mapbox/navigation-guidance-night-v\(version)")!
    }
}
