import Foundation

public protocol OfflineServiceObserver: AnyObject {
    func shouldRemove(region: OfflineRegion, forDomain: OfflineRegionDomain) -> Bool

    func didAddPending(region: OfflineRegion, forDomain: OfflineRegionDomain)
    func didStartDownloading(region: OfflineRegion, forDomain: OfflineRegionDomain)
    func didBecomeAvailable(region: OfflineRegion, forDomain: OfflineRegionDomain)
    func didBecomeIncomplete(region: OfflineRegion, forDomain: OfflineRegionDomain)
    func didBeginVerifying(region: OfflineRegion, forDomain: OfflineRegionDomain)
    func didBecomeExpired(region: OfflineRegion, forDomain: OfflineRegionDomain)
    func didBecomeErrored(region: OfflineRegion, forDomain: OfflineRegionDomain, withError error: OfflineRegionError?)
    func didStartDeleting(region: OfflineRegion, forDomain: OfflineRegionDomain)
    func didDelete(region: OfflineRegion, forDomain: OfflineRegionDomain)
    func log(message: String)
}
