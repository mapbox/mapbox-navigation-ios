import Foundation
import Mapbox


extension MGLAccountManager{
    
    // Mapbox China base API URL
    static let mapboxChinaBaseAPIURL = "https://api.mapbox.cn"
    
    //Mapbox China base URL host.
    static let mapboxChinaBaseURLHost = "api.mapbox.cn"
    
    /**
     The value of whether the map is China map or not.
     */
    @objc
    public class var hasChinaBaseURL : Bool{
        let apiBaseURL = Bundle.main.object(forInfoDictionaryKey:"MGLMapboxAPIBaseURL") as? String
        return apiBaseURL == mapboxChinaBaseAPIURL
    }
    
}
