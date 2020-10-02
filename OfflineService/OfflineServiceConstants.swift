import Foundation

struct OfflineServiceConstants {
    
    static let username = "1tap-nav"
    static let baseURL = "https://api.mapbox.com"
    static let accessToken: String = {
        guard let accessToken = Bundle.main.object(forInfoDictionaryKey: "MGLMapboxAccessToken") as? String else {
            assertionFailure("`accessToken` must be set in the Info.plist as `MGLMapboxAccessToken`.")
            return ""
        }
        
        return accessToken
    }()
    
    static let title = NSLocalizedString("OFFLINE_SERVICE_TITLE", value: "Offline Service", comment: "Title for UIViewController and UIAlertController.")
    static let close = NSLocalizedString("CLOSE_TITLE", value: "Close", comment: "Close title.")
    static let cancel = NSLocalizedString("CANCEL_TITLE", value: "Cancel", comment: "Cancel title.")
}
