import Foundation
import Turf
import MapboxDirections
import CoreLocation
import UIKit


typealias TLID = LocationCoordinate2D // + input and output bearing // incorrect
enum TLState {
    case red, green, unknown
    
    var color: UIColor {
        switch self {
        case .red:
            return .red
        case .green:
            return .green
        case .unknown:
            return .orange
        }
    }
    
    var text: String {
        switch self {
        case .red:
            return "red"
        case .green:
            return "green"
        case .unknown:
            return "??"
        }
    }
}
typealias TLPassage = (input: LocationDirection, output: LocationDirection)
typealias TLRecord = (id: TLID, date: Date, passage: TLPassage, state: TLState)


class TLCore {
    typealias DataType = [TLID: [TLRecord]]
    static let shared = TLCore()
    
    private init() {
//        data = storage.object(forKey: key) as? DataType
        // CLLocationCoordinate2D(latitude: 53.991858, longitude: 27.284656)
        // from 162.0 to 344.0
        let tlid = TLID(latitude: 53.993248, longitude: 27.283924)
        data = [tlid: [TLRecord(tlid,
                                Date(timeIntervalSinceNow: -60),
                                TLPassage(161.0, 340.0),
                                .red),
                       TLRecord(tlid,
                                Date(timeIntervalSinceNow: 31),
                                TLPassage(161.0, 340.0),
                                .green),
                       TLRecord(tlid,
                                Date(timeIntervalSinceNow: 61),
                                TLPassage(161.0, 340.0),
                                .red)]]
    }
    
    private let storage = UserDefaults.standard
    private let key = "TrafficLightsHacking"
    
    private var data: DataType?
    
    func save(record: TLRecord) {
        data?[record.0]?.append(record)
        
//        storage.set(data, forKey: key)
    }
    
    func loadRecords(by Id: TLID, passage: TLPassage) -> [TLRecord] {
        return data?[Id]?.filter {
            $0.passage == passage
        } ?? []
    }
}

extension TLID: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(longitude)
        hasher.combine(latitude)
    }
}


public class TLTools {
    private var tlStore = TLCore.shared
    private var trackingIntersection: (intersection: Intersection, distance: LocationDistance)? = nil
    private var currentTLState: TLState?
    
    public weak var delegate: TLDelegate? {
        get {
            stateTracker.delegate
        }
        set {
            stateTracker.delegate = newValue
        }
    }
    private var stateTracker = TLStateMachine()
    
    private func distanceToNextTrafficLight(from routeProgress: RouteProgress) -> LocationDistance? {
        // TLs may not be on intersections
        return routeProgress.currentLegProgress.currentStepProgress.userDistanceToUpcomingIntersection
    }
    
    private func nextTrafficLight(from routeProgress: RouteProgress) -> Intersection? {
        return routeProgress.currentLegProgress.currentStepProgress.upcomingIntersection
    }
    
    private func approachDirection(for intersection: Intersection, with bearing: LocationDirection?) -> LocationDirection? {
        guard var bearing = bearing else {
            return nil
        }
        
        bearing = (bearing + 180).remainder(dividingBy: 360)
        
        return intersection.headings.sorted {
            abs($0 - bearing) < abs($1 - bearing) // wrong! Mind 360 -> 0 cycle
        }.first!
    }
    
    private func saveState(intersection: Intersection, approach: LocationDirection, outlet: LocationDirection, state: TLState) {
        let passage = TLPassage(approach,
                                outlet)
        let record = TLRecord(intersection.location,
                              Date(),
                              passage,
                              state)
        
        tlStore.save(record: record)
        printRecord(record)
        currentTLState = state
        
        stateTracker.detectedState(state, for: intersection.location)
//        delegate?.trafficLightUpdated(at: intersection.location,
//                                      state: state == .green ? "green" : "red",
//                                      color: state == .green ? .green : .red)
    }
    
    private func printRecord(_ record: TLRecord) {
        print(">>> \(record.0)")
        print(">>> from \(record.2.input) to \(record.2.output)")
        print(">>> \(record.3)")
    }
    
    public init() {}
    
    public func detectTrafficLightState(using routeProgress: RouteProgress, at location: CLLocation) {
        // get distance to the next traffic light

        // detect distance delta with previous update (using speed?)
        guard let tlDistance = distanceToNextTrafficLight(from: routeProgress),
              let currentIntersection = nextTrafficLight(from: routeProgress) else {
                  // if we were tracking an intersection
                  if let trackingIntersection = trackingIntersection,
                     let approachDirection = approachDirection(for: trackingIntersection.intersection, with: location.course),
                     let outletIndex = trackingIntersection.intersection.outletIndex {
                      
                      let outletDirection = trackingIntersection.intersection.headings[outletIndex]
                      
                      print(">>> Passed last Intersection:")
                      saveState(intersection: trackingIntersection.intersection,
                                approach: approachDirection,
                                outlet: outletDirection,
                                state: .green)
                      // we passed it and are to arrive next
                      self.trackingIntersection = nil
                      currentTLState = nil
                  }
                  return
              }
        
        // if we are not tracking -> start and exit
        guard let trackingIntersection = trackingIntersection else {
            self.trackingIntersection = (currentIntersection,
                                         tlDistance)
            currentTLState = nil
//            delegate?.trafficLightUpdated(at: currentIntersection.location,
//                                          state: "??",
//                                          color: .yellow)
            return
        }

        // we were not at departure or arriving
        guard let approachDirection = approachDirection(for: trackingIntersection.intersection, with: location.course),
              let outletIndex = trackingIntersection.intersection.outletIndex else {
                  return
              }
        
        let outletDirection = trackingIntersection.intersection.headings[outletIndex]
        
        // if this is not the same intersection -> record Green on previos and start tracking new
        guard trackingIntersection.intersection == currentIntersection else {
            print(">>> Intersection changed:")
            saveState(intersection: trackingIntersection.intersection,
                      approach: approachDirection,
                      outlet: outletDirection,
                      state: .green)
            self.trackingIntersection = (currentIntersection,
                                         tlDistance)
            currentTLState = nil
            return
        }
        
        // if this is the same intersection:
        // ensure we are not too far away
        guard tlDistance < 100 else {
            return
        }
        
//        delegate?.trafficLightUpdated(at: trackingIntersection.intersection.location,
//                                      state: "??",
//                                      color: .yellow)
        
        let marginDistance: LocationDistance = 2
        if tlDistance < trackingIntersection.distance - marginDistance {
            // if distance has decreased (by what value?) -> update distance
//            self.trackingIntersection?.distance = tlDistance
            // if it was recorded RED for this TL -> TODO: record GREEN
            if currentTLState == .red {
                print(">>> Was red now green:")
                saveState(intersection: trackingIntersection.intersection,
                          approach: approachDirection,
                          outlet: outletDirection,
                          state: .green)
            }
        } else { // if distance is the same -> record RED
            if location.speed < 1 && currentTLState != .red { // avoid spamming RED records
                print(">>> No distance moved:")
                saveState(intersection: trackingIntersection.intersection,
                          approach: approachDirection,
                          outlet: outletDirection,
                          state: .red)
            }
        }
        self.trackingIntersection?.distance = tlDistance
    }
    
    public func predictTrafficLightState(using routeProgress: RouteProgress, at location: CLLocation) {
        // get distance to the next traffic light
        // ensure we are not too far away
        guard let tlDistance = distanceToNextTrafficLight(from: routeProgress),
              tlDistance < 100 else {
            return
        }
        
        // get known TL data
        guard let trackingIntersection = trackingIntersection else {
            return
        }

        guard let approachDirection = approachDirection(for: trackingIntersection.intersection, with: location.course),
              let outletIndex = trackingIntersection.intersection.outletIndex else {
                  return
              }
        
        let outletDirection = trackingIntersection.intersection.headings[outletIndex]
        
        let records = tlStore.loadRecords(by: trackingIntersection.intersection.location,
                                          passage: TLPassage(approachDirection,
                                                             outletDirection))
        let calendar = Calendar.current
        var previous = (TimeInterval.greatestFiniteMagnitude, Optional<TLRecord>.none)
        var next = (-TimeInterval.greatestFiniteMagnitude, Optional<TLRecord>.none)
        
        let currentComponents = calendar.dateComponents([.hour, .minute, .second], from: Date())
        records.forEach {
            let delta = timeDelta(currentComponents,
                                  calendar.dateComponents([.hour, .minute, .second], from: $0.date))
            
            if delta > 0 && delta < previous.0 {
                previous = (delta, $0)
            }
            if delta < 0 && delta > next.0 {
                next = (delta, $0)
            }
        }
        
        // calculate the prediction
        // TODO: design a schedule calculation
        // let schedule = ScheduleCreator(records: records)
        // let currentTLState = schedule.currentState // (state: TLState, starting: Date(), duration: TimeInterval)
        // let upcomingTLState = schedule.nextState // (state: TLState, starting: Date(), duration: TimeInterval)
        
        // current state == previos state
        // upcoming state == next state in delta seconds
        if let currentState = previous.1?.state { // do filter if this was too long ago
            stateTracker.predictedCurrentState(currentState,
                                               for: trackingIntersection.intersection.location)
        }
        if let upcomingState = next.1?.state { // do filter if this is a far future
            stateTracker.predictedNextState(upcomingState,
                                            for: trackingIntersection.intersection.location,
                                            in: next.0 * -1)
        }
        
        if previous.1 == nil && next.1 == nil {
            stateTracker.predictedCurrentState(.unknown,
                                               for: trackingIntersection.intersection.location)
        }
    }
    
    private func timeDelta(_ lhs: DateComponents, _ rhs: DateComponents) -> TimeInterval {
        // error! Mind the 23:59 -> 00:00 loop
        var lhsInterval = TimeInterval(((lhs.hour ?? 0) * 3600) + ((lhs.minute ?? 0) * 60))
        lhsInterval += TimeInterval(lhs.second ?? 0) // blame the compiler >_<
        var rhsInterval = TimeInterval(((rhs.hour ?? 0) * 3600) + ((rhs.minute ?? 0) * 60))
        rhsInterval += TimeInterval(rhs.second ?? 0)
        
        return lhsInterval - rhsInterval
    }
}

class TLStateMachine {
    weak var delegate: TLDelegate?
    var currentState: TLState?
    var stateOrigin: StateOrigin?
    var currentID: TLID?
    var predictionSuffix: String?
    
    enum StateOrigin {
        case detected, predicted
    }
    
    func detectedState(_ state: TLState, for tlid: TLID) {
        verifySuffix(for: tlid)
            
        currentState = state
        currentID = tlid
        stateOrigin = .detected
        
        reportTL()
    }
    
    func predictedCurrentState(_ state: TLState, for tlid: TLID) {
        if stateOrigin != .detected || currentID != tlid {
            verifySuffix(for: tlid)
            
            currentState = state
            currentID = tlid
            stateOrigin = .predicted
            
            reportTL()
        }
    }
    
    func predictedNextState(_ state: TLState, for tlid: TLID, in seconds: TimeInterval) {
        predictionSuffix = " next: \(state.text) in \(seconds) sec"
        // add suffix?
        reportTL()
    }
    
    func verifySuffix(for tlid: TLID) {
        if tlid != currentID {
            predictionSuffix = nil
        }
    }
    
    func reportTL() {
        guard let tlid = currentID,
              let state = currentState,
              let stateOrigin = stateOrigin else {
                  return
              }
        let text = (stateOrigin == .detected ? "Detected " : "Predicted ") + state.text + (predictionSuffix ?? "")
        delegate?.trafficLightUpdated(at: tlid,
                                      state: text,
                                      color: state.color)
    }
}

public protocol TLDelegate: AnyObject {
    func trafficLightUpdated(at: LocationCoordinate2D, state: String, color: UIColor)
}
