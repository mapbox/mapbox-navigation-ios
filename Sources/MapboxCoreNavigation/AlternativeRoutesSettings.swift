
import Foundation

public class AlternativeRoutesOptions {
    public var enabled = true
    
    /**
     * Enables requesting alternate routes as soon as we pass a fork with an alternate route.
     *  Passed altrenal route will disappear from the list of alternative routes at any value.
     *  Enabled by default.
     */
    public var refreshAfterAlternativeFork = true
    
    /**
     * Enables alternative routes periodic polling. Polling starts only if there are no alternatives.
     *  This will help avoid a situation when server has not returned any alternatives, but may return them later during the ride.
     *  Refreshes will be stopped if status.routeState is Invalid, OffRoute or Complete. And will be resumed otherwise.
     *  Now it can consume a lot of traffic!
     *  Disabled by default.
     */
    public var refreshWhenNoAvailableAlternatives = false
    public var refreshInterval: TimeInterval = 3 * 60 // related to above
    
    public init(refreshAfterAlternativeFork: Bool = true,
                refreshWhenNoAvailableAlternatives: Bool = false,
                refreshInterval: TimeInterval = 3 * 60) {
        self.refreshAfterAlternativeFork = refreshAfterAlternativeFork
        self.refreshWhenNoAvailableAlternatives = refreshWhenNoAvailableAlternatives
        self.refreshInterval = refreshInterval
    }
}
