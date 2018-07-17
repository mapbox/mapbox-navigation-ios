import Foundation

class NetworkConfiguration : NSObject{
    @objc static let sharedConfiguration = NetworkConfiguration()
    
    // The current API base URL of map
    private var apiBaseURL : String?
    
    // The PRC base URL for Mapbox APIs other than the telemetry API.
    private let mapboxChinaBaseAPIURL = "https://api.mapbox.cn"
    
    // The base URL host for Mapbox China
    public let mapboxChinaBaseURLHost = "api.mapbox.cn"
    
    // The URL String of China map style.
    public let mapboxChinaStyleURL = "mapbox://styles/mapbox/streets-zh-v1"
    
    // Value of whether the map is China map or not
    public var hasChinaBaseURL : Bool{
        if(apiBaseURL == mapboxChinaBaseAPIURL){
            return true
        }
        return false
    }
    
    private override init() {
        super.init()
        apiBaseURL = Bundle.main.object(forInfoDictionaryKey:"MGLMapboxAPIBaseURL") as? String
    }
    
}
