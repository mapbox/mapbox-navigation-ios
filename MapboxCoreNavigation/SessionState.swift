import Foundation
import CoreLocation
import MapboxDirections


struct SessionState {
    let identifier = UUID()
    var departureTimestamp: Date?
    var arrivalTimestamp: Date?
    
    var totalDistanceCompleted: CLLocationDistance = 0
    
    var numberOfReroutes = 0
    var lastRerouteDate: Date?
    
    var currentRoute: Route
    var originalRoute: Route
    
    var timeSpentInPortrait: TimeInterval = 0
    var timeSpentInLandscape: TimeInterval = 0
    
    var lastTimeInLandscape = Date()
    var lastTimeInPortrait = Date()
    
    var timeSpentInForeground: TimeInterval = 0
    var timeSpentInBackground: TimeInterval = 0
    
    var lastTimeInForeground = Date()
    var lastTimeInBackground = Date()
    
    var pastLocations = FixedLengthQueue<CLLocation>(length: 40)
    
    init(currentRoute: Route, originalRoute: Route) {
        self.currentRoute = currentRoute
        self.originalRoute = originalRoute
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
