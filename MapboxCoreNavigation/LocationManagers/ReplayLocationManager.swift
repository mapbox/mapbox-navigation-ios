import Foundation
import CoreLocation

/**
 `ReplayLocationManager` replays an array of locations exactly as they were
 recorded with the single exception of the location’s timestamp which will be
 adjusted by interval between locations.
 */
public class ReplayLocationManager: NavigationLocationManager {
    
    /**
     `speedMultiplier` adjusts the speed of the replay.
     */
    public var speedMultiplier: TimeInterval = 1
    
    var currentIndex: Int = 0
    
    /**
     `locations` to be replayed. These locations must be sorted by timestamp.
     */
    public var locations: [CLLocation]! {
        didSet {
            currentIndex = 0
        }
    }
    
    public init(locations: [CLLocation]) {
        self.locations = locations
        super.init()
    }
    
    deinit {
        stopUpdatingLocation()
    }
    
    override open func startUpdatingLocation() {
        tick()
    }
    
    override open func stopUpdatingLocation() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(tick), object: nil)
    }
    
    @objc fileprivate func tick() {
        let location = locations[currentIndex]
        lastKnownLocation = location
        delegate?.locationManager?(self, didUpdateLocations: [location])
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(tick), object: nil)
        
        if currentIndex < locations.count - 1  {
            let nextLocation = locations[currentIndex+1]
            let interval = nextLocation.timestamp.timeIntervalSince(location.timestamp) / speedMultiplier
            perform(#selector(tick), with: nil, afterDelay: interval)
            currentIndex += 1
        } else {
            currentIndex = 0
        }
    }
}
