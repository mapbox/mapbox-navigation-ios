import Foundation
import CoreLocation

/**
 `ReplayLocationManager` replays an array of locations exactly as they were
 recorded with the single exception of the location’s timestamp which will be
 adjusted by interval between locations.
 */
open class ReplayLocationManager: NavigationLocationManager {
    
    // MARK: Specifying Simulation
    
    /**
     `speedMultiplier` adjusts the speed of the replay.
     */
    public var speedMultiplier: TimeInterval = 1
    
    /**
     `locations` to be replayed.
     */
    public var locations: [CLLocation] {
        didSet {
            currentIndex = 0
            verifyParameters()
        }
    }
    
    /**
     `simulatesLocation` used to indicate whether the location manager is providing simulated locations.
     - seealso: `NavigationMapView.simulatesLocation`
     */
    public override var simulatesLocation: Bool {
        get { return true }
        set { super.simulatesLocation = newValue }
    }
    
    override open var location: CLLocation? {
        get {
            return synthesizedLocation
        }
        set {
            synthesizedLocation = newValue
        }
    }
    
    var currentIndex: Int = 0
    
    var startDate: Date?
    
    private var synthesizedLocation: CLLocation?

    /**
     A handler that is called when `ReplayLocationManager` finished replaying `locations` and about to start from the
     beginning. Return false to stop replaying `locations`.
     */
    var onReplayLoopCompleted: ((ReplayLocationManager) -> Bool)?

    /**
     A handler that is called on each replayed location along with the location index in `locations` array.
     */
    var onTick: ((_ index: Int, CLLocation) -> Void)?
    
    public init(locations: [CLLocation]) {
        self.locations = locations.sorted { $0.timestamp < $1.timestamp }
        super.init()
        verifyParameters()
    }
    
    deinit {
        stopUpdatingLocation()
    }
    
    override open func startUpdatingLocation() {
        startDate = Date()
        tick()
        assert(!locations.isEmpty, "Replay doesn't work with empty locations.")
    }
    
    override open func stopUpdatingLocation() {
        startDate = nil
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(tick), object: nil)
    }
    
    @objc internal func tick() {
        guard let startDate = startDate else { return }

        let location = locations[currentIndex]
        synthesizedLocation = location
        delegate?.locationManager?(self, didUpdateLocations: [location])
        onTick?(currentIndex, location)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(tick), object: nil)
        
        if currentIndex >= locations.count - 1 {
            let startFromBeginning = onReplayLoopCompleted?(self) ?? true
            if startFromBeginning {
                currentIndex = 0
            }
            else {
                return
            }
        }
        
        let nextLocation = locations[currentIndex+1]
        let interval = nextLocation.timestamp.timeIntervalSince(location.timestamp) / TimeInterval(speedMultiplier)
        let intervalSinceStart = Date().timeIntervalSince(startDate)+interval
        let actualInterval = nextLocation.timestamp.timeIntervalSince(locations.first!.timestamp)
        let diff = min(max(0, intervalSinceStart-actualInterval), 0.9) // Don't try to resync more than 0.9 seconds per location update
        let syncedInterval = interval-diff

        perform(#selector(tick), with: nil, afterDelay: syncedInterval)
        currentIndex += 1
    }

    private func verifyParameters() {
        precondition(!locations.isEmpty)
    }
}
