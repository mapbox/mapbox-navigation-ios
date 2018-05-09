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
    public func navigationGuidanceDayStyle(version: Int) -> URL {
        return URL(string: "mapbox://styles/mapbox/navigation-guidance-day-v\(version)")!
    }

    @objc
    public func navigationGuidanceNightStyle(version: Int) -> URL {
        return URL(string: "mapbox://styles/mapbox/navigation-guidance-night-v\(version)")!
    }
}
