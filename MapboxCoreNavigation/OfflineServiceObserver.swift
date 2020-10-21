import Foundation

public protocol OfflineServiceObserver: AnyObject {
    /**
     Offline pack deletion requires acknowledgment by all listeners. Default answer is true
     */
    func shouldRemove(region: OfflineRegion, forDomain: OfflineRegionDomain) -> Bool

    func didAddPending(region: OfflineRegion, forDomain: OfflineRegionDomain)

    func didStartDownloading(region: OfflineRegion, forDomain: OfflineRegionDomain)

    func didBecomeAvailable(region: OfflineRegion, forDomain: OfflineRegionDomain)

    func didBecomeUnavailable(region: OfflineRegion)

    func didBecomeIncomplete(region: OfflineRegion, forDomain: OfflineRegionDomain)

    func didBeginVerifying(region: OfflineRegion, forDomain: OfflineRegionDomain)

    func didBecomeExpired(region: OfflineRegion, forDomain: OfflineRegionDomain)

    func didBecomeErrored(region: OfflineRegion, forDomain: OfflineRegionDomain, withError error: OfflineRegionError?)

    func didStartDeleting(region: OfflineRegion, forDomain: OfflineRegionDomain)

    func didDelete(region: OfflineRegion, forDomain: OfflineRegionDomain)

    /**
     Called once all offline regions that have been downloaded to disk are initialized
     */
    func initialized()

    /**
     Called with log messages. They are informative and can be disregarded
     */
    func log(message: String)

    /**
     Called when there are no operations are in progress anymore
     */
    func idle()
}

public extension OfflineServiceObserver {
    func shouldRemove(region: OfflineRegion, forDomain: OfflineRegionDomain) -> Bool {
        return true
    }

    func didAddPending(region: OfflineRegion, forDomain: OfflineRegionDomain) {}

    func didStartDownloading(region: OfflineRegion, forDomain: OfflineRegionDomain) {}

    func didBecomeAvailable(region: OfflineRegion, forDomain: OfflineRegionDomain) {}

    func didBecomeUnavailable(region: OfflineRegion) {}

    func didBecomeIncomplete(region: OfflineRegion, forDomain: OfflineRegionDomain) {}

    func didBeginVerifying(region: OfflineRegion, forDomain: OfflineRegionDomain) {}

    func didBecomeExpired(region: OfflineRegion, forDomain: OfflineRegionDomain) {}

    func didBecomeErrored(region: OfflineRegion, forDomain: OfflineRegionDomain, withError error: OfflineRegionError?) {}

    func didStartDeleting(region: OfflineRegion, forDomain: OfflineRegionDomain) {}

    func didDelete(region: OfflineRegion, forDomain: OfflineRegionDomain) {}

    func initialized() {}

    func log(message: String) {}

    func idle() {}
}
