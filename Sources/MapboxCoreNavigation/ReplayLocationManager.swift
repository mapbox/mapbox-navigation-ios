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
     A handler that is called when `ReplayLocationManager` finished replaying `locations`.
     Return true to start replay from the beginning.
     */
    public var replayCompletionHandler: ((ReplayLocationManager) -> Bool)?

    /**
     A handler that is called on each replayed location along with the location index in `locations` array.
     */
    var onTick: ((_ index: Int, CLLocation) -> Void)?

    private var nextTickWorkItem: DispatchWorkItem?
    
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
        nextTickWorkItem?.cancel()
    }
    
    @objc internal func tick() {
        guard let startDate = startDate else { return }

        func sendTick(with location: CLLocation) {
            synthesizedLocation = location
            delegate?.locationManager?(self, didUpdateLocations: [location])
            onTick?(currentIndex, location)
            nextTickWorkItem?.cancel()
        }

        func scheduleNextTick(afterDelay delay: TimeInterval) {
            let nextTickWorkItem = DispatchWorkItem(block: { [weak self] in
                self?.tick()
            })
            self.nextTickWorkItem = nextTickWorkItem
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: nextTickWorkItem)
        }

        guard locations.count > 1 else {
            sendTick(with: locations[0])
            let startFromBeginning = replayCompletionHandler?(self) ?? false
            if startFromBeginning {
                advanceLocationsForNextLoop()
                scheduleNextTick(afterDelay: 1 / speedMultiplier)
            }
            return
        }

        let location = locations[currentIndex]
        sendTick(with: location)

        var nextIndex = currentIndex + 1
        if nextIndex == locations.count {
            let startFromBeginning = replayCompletionHandler?(self) ?? false
            if startFromBeginning {
                advanceLocationsForNextLoop()
                nextIndex = 0
            }
            else {
                return
            }
        }

        let nextLocation = locations[nextIndex]
        let interval = nextLocation.timestamp.timeIntervalSince(location.timestamp) / TimeInterval(speedMultiplier)
        let intervalSinceStart = Date().timeIntervalSince(startDate)+interval
        let actualInterval = nextLocation.timestamp.timeIntervalSince(locations.first!.timestamp)
        let diff = min(max(0, intervalSinceStart-actualInterval), 0.9) // Don't try to resync more than 0.9 seconds per location update
        let syncedInterval = interval-diff

        scheduleNextTick(afterDelay: syncedInterval)
        currentIndex = nextIndex
    }

    private func verifyParameters() {
        precondition(!locations.isEmpty)
    }

    /// Shift `locations` so that sent locations always have increasing timestamps, taking into account location deltas.
    private func advanceLocationsForNextLoop() {
        /// Previous location that is used to calculate deltas between locations.
        var previousOldLocation: CLLocation = locations.last!
        /// Previous timestamp that is used to advance timestamps.
        var previousNewLocationTimestamp = previousOldLocation.timestamp

        for (idx, location) in locations.enumerated() {
            let delta: TimeInterval = idx == 0 ? 1 : location.timestamp.timeIntervalSince(previousOldLocation.timestamp)
            let newTimestamp = previousNewLocationTimestamp.addingTimeInterval(delta)
            previousOldLocation = location
            locations[idx] = location.shifted(to: newTimestamp)
            previousNewLocationTimestamp = newTimestamp
        }
    }
}
