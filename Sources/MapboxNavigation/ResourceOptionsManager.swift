import Foundation
import MapboxMaps

extension ResourceOptionsManager {
    
    static let mapboxChinaBaseAPIURL = "https://api.mapbox.cn"
    
    /**
     Returns true if the map's endpoint is China.
     */
    public class var hasChinaBaseURL: Bool {
        let apiBaseURL = Bundle.main.object(forInfoDictionaryKey: "MGLMapboxAPIBaseURL") as? String
        return apiBaseURL == mapboxChinaBaseAPIURL
    }
}
