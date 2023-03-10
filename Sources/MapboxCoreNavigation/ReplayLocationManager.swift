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
    
    private var _locations: [CLLocation]
    /**
     `locations` to be replayed.
     */
    public var locations: [CLLocation] {
        get {
            _locations
        }
        set {
            _locations = newValue
            currentIndex = 0
            verifyParameters()
            self.events = _locations.map { ReplayEvent(from: $0) }
        }
    }
    
    private(set) var events: [ReplayEvent]
    
    /**
     Events listener that will receive history events if replaying a `History`.
     */
    public weak var eventsListener: ReplayManagerHistoryEventsListener? = nil
    
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
        self._locations = locations.sorted { $0.timestamp < $1.timestamp }
        self.events = locations.map { ReplayEvent(from: $0) }
        super.init()
        
        verifyParameters()
        advanceEventsForNextLoop(starting: Date())
    }
    
    public init(history: History) {
        self._locations = history.rawLocations.sorted { $0.timestamp < $1.timestamp }
        self.events = history.events.map { ReplayEvent(from: $0) }
        
        super.init()
        
        verifyParameters()
        advanceEventsForNextLoop(starting: Date())
    }
    
    public convenience init(history: History, listener: ReplayManagerHistoryEventsListener?) {
        self.init(history: history)
        self.eventsListener = listener
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

        func sendTick(_ event: ReplayEvent) {
            switch event.kind {
            case .location(let location):
                synthesizedLocation = location
                delegate?.locationManager?(self, didUpdateLocations: [location])
                onTick?(currentIndex, location)
                nextTickWorkItem?.cancel()
            case .historyEvent(let historyEvent):
                if let locationUpdate = historyEvent as? LocationUpdateHistoryEvent {
                    delegate?.locationManager?(self, didUpdateLocations: [locationUpdate.location])
                }
                eventsListener?.replyLocationManager(self, published: historyEvent)
            }
        }

        func scheduleNextTick(afterDelay delay: TimeInterval) {
            let nextTickWorkItem = DispatchWorkItem(block: { [weak self] in
                self?.tick()
            })
            self.nextTickWorkItem = nextTickWorkItem
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: nextTickWorkItem)
        }

        guard events.count > 1 else {
            sendTick(events[0])
            
            let startFromBeginning = replayCompletionHandler?(self) ?? false
            if startFromBeginning {
                advanceEventsForNextLoop()
                scheduleNextTick(afterDelay: 1 / speedMultiplier)
            }
            return
        }

        let event = events[currentIndex]
        sendTick(event)

        var nextIndex = currentIndex + 1
        if nextIndex == events.count {
            let startFromBeginning = replayCompletionHandler?(self) ?? false
            if startFromBeginning {
                advanceEventsForNextLoop()
                nextIndex = 0
            }
            else {
                return
            }
        }

        let nextEvent = events[nextIndex]
        let interval = nextEvent.date.timeIntervalSince(event.date) / TimeInterval(speedMultiplier)
        let intervalSinceStart = Date().timeIntervalSince(startDate)+interval
        let actualInterval = nextEvent.date.timeIntervalSince(events.first!.date)
        let diff = min(max(0, intervalSinceStart-actualInterval), 0.9) // Don't try to resync more than 0.9 seconds per location update
        let syncedInterval = interval-diff

        scheduleNextTick(afterDelay: syncedInterval)
        currentIndex = nextIndex
    }

    private func verifyParameters() {
        precondition(!locations.isEmpty)
    }

    /// Shift `events` and  `locations` so that sent locations always have increasing timestamps, taking into account event deltas.
    private func advanceEventsForNextLoop(starting startDate: Date? = nil) {
        /// Previous location that is used to calculate deltas between locations.
        var previousOldLocation = events.last!
        /// Previous timestamp that is used to advance timestamps.
        var previousNewLocationTimestamp = startDate ?? previousOldLocation.date

        var advancedLocations: [CLLocation] = []
        
        for (idx, event) in events.enumerated() {
            let delta: TimeInterval = idx == 0 ? 1 : event.date.timeIntervalSince(previousOldLocation.date)
            let newTimestamp = previousNewLocationTimestamp.addingTimeInterval(delta)
            previousOldLocation = event
            let shiftedEvent = event.shifted(to: newTimestamp)
            events[idx] = shiftedEvent
            
            if case let .location(location) = shiftedEvent.kind {
                advancedLocations.append(location)
            } else if case let .historyEvent(historyEvent) = shiftedEvent.kind,
                let locationEvent = historyEvent as? LocationUpdateHistoryEvent {
                advancedLocations.append(locationEvent.location)
            }
            
            previousNewLocationTimestamp = newTimestamp
        }
        self._locations = advancedLocations
    }
}

/**
 `ReplayLocationManager`'s listener that will receive events feed when it is replaying a `History` data.
 */
public protocol ReplayManagerHistoryEventsListener: AnyObject {
    func replyLocationManager(_ manager: ReplayLocationManager, published event: HistoryEvent)
}


struct ReplayEvent {
    var date: Date
    
    enum Kind {
        case location(CLLocation)
        case historyEvent(HistoryEvent)
    }
    var kind: Kind
    
    func shifted(to date: Date) -> ReplayEvent {
        switch kind {
        case .location(let location):
            return ReplayEvent(from: location.shifted(to: date))
        case .historyEvent(let historyEvent):
            switch historyEvent {
            case let event as LocationUpdateHistoryEvent:
                return ReplayEvent(from: LocationUpdateHistoryEvent(timestamp: date.timeIntervalSince1970,
                                                                    location: event.location.shifted(to: date)))
            case let event as RouteAssignmentHistoryEvent:
                return ReplayEvent(from: RouteAssignmentHistoryEvent(timestamp: date.timeIntervalSince1970,
                                                                     routeResponse: event.routeResponse))
            case let event as UserPushedHistoryEvent:
                return ReplayEvent(from: UserPushedHistoryEvent(timestamp: date.timeIntervalSince1970,
                                                                type: event.type,
                                                                properties: event.properties))
            case is UnknownHistoryEvent:
                fallthrough
            default:
                return ReplayEvent(from: UnknownHistoryEvent(timestamp: date.timeIntervalSince1970))
            }
        }
    }
    
    init(from location: CLLocation) {
        self.date = location.timestamp
        self.kind = .location(location)
    }
    
    init(from historyEvent: HistoryEvent) {
        self.date = Date(timeIntervalSince1970: historyEvent.timestamp)
        self.kind = .historyEvent(historyEvent)
    }
}
