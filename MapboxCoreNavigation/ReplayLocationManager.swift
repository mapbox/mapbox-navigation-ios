import Foundation
import CoreLocation

/**
 `ReplayLocationManager` replays an array of locations exactly as they were
 recorded with the single exception of the location’s timestamp which will be
 adjusted by interval between locations.
 */
@objc(MBReplayLocationManager)
public class ReplayLocationManager: NavigationLocationManager {
    
    /**
     `speedMultiplier` adjusts the speed of the replay.
     */
    @objc public var speedMultiplier: TimeInterval = 1
    
    var currentIndex: Int = 0
    
    var startDate: Date?
    
    /**
     `locations` to be replayed.
     */
    @objc public var locations: [CLLocation]! {
        didSet {
            currentIndex = 0
        }
    }
    
    @objc override public var location: CLLocation? {
        get {
            return lastKnownLocation
        }
    }
    
    public init(locations: [CLLocation]) {
        self.locations = locations.sorted { $0.timestamp < $1.timestamp }
        super.init()
    }
    
    deinit {
        stopUpdatingLocation()
    }
    
    override open func startUpdatingLocation() {
        startDate = Date()
        tick()
    }
    
    override open func stopUpdatingLocation() {
        startDate = nil
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(tick), object: nil)
    }
    
    @objc fileprivate func tick() {
        guard let startDate = startDate else { return }
        let location = locations[currentIndex]
        lastKnownLocation = location
        delegate?.locationManager?(self, didUpdateLocations: [location])
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(tick), object: nil)
        
        if currentIndex < locations.count - 1 {
            let nextLocation = locations[currentIndex+1]
            let interval = nextLocation.timestamp.timeIntervalSince(location.timestamp) / TimeInterval(speedMultiplier)
            let intervalSinceStart = Date().timeIntervalSince(startDate)+interval
            let actualInterval = nextLocation.timestamp.timeIntervalSince(locations.first!.timestamp)
            let diff = min(max(0, intervalSinceStart-actualInterval), 0.9) // Don't try to resync more than 0.9 seconds per location update
            let syncedInterval = interval-diff
            
            perform(#selector(tick), with: nil, afterDelay: syncedInterval)
            currentIndex += 1
        } else {
            currentIndex = 0
        }
    }
}
