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
    static let tilesVersion = "2020_10_11-03_00_00"
    
    static let title = NSLocalizedString("OFFLINE_SERVICE_TITLE", value: "Offline Service", comment: "Title for UIViewController and UIAlertController.")
    static let close = NSLocalizedString("CLOSE_TITLE", value: "Close", comment: "Close title.")
    static let cancel = NSLocalizedString("CANCEL_TITLE", value: "Cancel", comment: "Cancel title.")
    static let mapsPack = NSLocalizedString("MAPS_PACK_TITLE", value: "Maps pack", comment: "Maps pack.")
    static let navigationPack = NSLocalizedString("NAVIGATION_PACK_TITLE", value: "Navigation pack", comment: "Navigation pack.")
    static let selectActionTitle = NSLocalizedString("SELECT_ACTION_TITLE", value: "Please select appropriate action.", comment: "Please select appropriate action.")
    static let downloadMapsPack = NSLocalizedString("DOWNLOAD_MAPS_TITLE", value: "Download Maps Pack", comment: "Download Maps Pack.")
    static let deleteMapsPack = NSLocalizedString("DELETE_MAPS_TITLE", value: "Delete Maps Pack", comment: "Delete Maps Pack.")
    static let downloadNavigationPack = NSLocalizedString("DOWNLOAD_NAVIGATION_TITLE", value: "Download Navigation Pack", comment: "Download Navigation Pack.")
    static let deleteNavigationPack = NSLocalizedString("DELETE_NAVIGATION_PACK_TITLE", value: "Delete Navigation Pack", comment: "Delete Navigation Pack.")
    static let lastUpdated = NSLocalizedString("LAST_UPDATED_TITLE", value: "Last updated", comment: "Last updated.")
    static let size = NSLocalizedString("SIZE_TITLE", value: "Size", comment: "Size.")
    static let clearMapsAmbientCache = NSLocalizedString("CLEAR_MAPS_AMBIENT_CACHE_TITLE", value: "Clear maps ambient cache", comment: "Clear maps ambient cache.")
    static let clearNavigationAmbientCache = NSLocalizedString("CLEAR_NAVIGATION_AMBIENT_CACHE_TITLE", value: "Clear navigation ambient cache", comment: "Clear navigation ambient cache.")
}
