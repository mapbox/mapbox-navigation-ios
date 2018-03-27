import Foundation
import MapboxMobileEvents

class EventsManagerSpy: MMEEventsManager {

    var recentEvents: NSArray = NSMutableArray()

    func reset() {
        recentEvents = NSMutableArray()
    }
}
