import Foundation
import CoreLocation
import MapboxDirections
import UIKit.UIDevice

/**
 `SessionState` is a struct which stores information needed to send to the Mapbox telemetry platform.
 */
struct SessionState {
    let identifier = UUID()
    var departureTimestamp: Date?
    var arrivalTimestamp: Date?
    
    var totalDistanceCompleted: CLLocationDistance = 0
    
    var numberOfReroutes = 0
    var lastRerouteDate: Date?
    
    var currentRoute: Route?
    var originalRoute: Route?
    var routeIdentifier: String?
    
    var terminated = false
    
    private(set) var timeSpentInPortrait: TimeInterval = 0
    private(set) var timeSpentInLandscape: TimeInterval = 0
    
    private(set) var lastTimeInLandscape = Date()
    private(set) var lastTimeInPortrait = Date()
    
    private(set) var timeSpentInForeground: TimeInterval = 0
    private(set) var timeSpentInBackground: TimeInterval = 0
    
    private(set) var lastTimeInForeground = Date()
    private(set) var lastTimeInBackground = Date()
    
    private var lastReportedWaypoint: Waypoint?
    
    var pastLocations = FixedLengthQueue<CLLocation>(length: 40)
    
    init(currentRoute: Route? = nil, originalRoute: Route? = nil, routeIdentifier: String? = nil) {
        self.currentRoute = currentRoute
        self.originalRoute = originalRoute
        self.routeIdentifier = routeIdentifier
    }
    
    public mutating func reportChange(to orientation: UIDeviceOrientation) {
        if orientation.isPortrait {
            timeSpentInLandscape += abs(lastTimeInPortrait.timeIntervalSinceNow)
            lastTimeInPortrait = Date()
        } else if orientation.isLandscape {
            timeSpentInPortrait += abs(lastTimeInLandscape.timeIntervalSinceNow)
            lastTimeInLandscape = Date()
        }
    }
    
    public mutating func reportChange(to applicationState: UIApplication.State) {
        if applicationState == .active {
            timeSpentInForeground += abs(lastTimeInBackground.timeIntervalSinceNow)
            
            lastTimeInForeground = Date()
        } else if applicationState == .background {
            timeSpentInBackground += abs(lastTimeInForeground.timeIntervalSinceNow)
            lastTimeInBackground = Date()
        }
    }
}

class FixedLengthQueue<T> {
    private var objects = Array<T>()
    private var length: Int
    
    public init(length: Int) {
        self.length = length
    }
    
    public func push(_ obj: T) {
        objects.append(obj)
        if objects.count == length {
            objects.remove(at: 0)
        }
    }
    
    public var allObjects: Array<T> {
        get {
            return Array(objects)
        }
    }
}
