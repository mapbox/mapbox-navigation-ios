import Foundation
import Dispatch

class CountdownTimer {
    enum State {
        case armed, disarmed
    }
    
    typealias Payload = DispatchSource.DispatchSourceHandler
    static let defaultAccuracy: DispatchTimeInterval = .milliseconds(500)
    var countdownInterval: DispatchTimeInterval {
        didSet {
            reset()
        }
    }
    private var deadline: DispatchTime { return .now() + countdownInterval }
    let accuracy: DispatchTimeInterval
    let payload: Payload
    let timerQueue = DispatchQueue(label: "com.mapbox.coreNavigation.timer.countdown", qos: DispatchQoS.background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
    let executionQueue: DispatchQueue
    let timer: DispatchSourceTimer
    
    private(set) var state: State = .disarmed
    
    init(countdown: DispatchTimeInterval, accuracy: DispatchTimeInterval = defaultAccuracy, executingOn executionQueue: DispatchQueue = .main, payload: @escaping Payload) {
        countdownInterval = countdown
        self.executionQueue = executionQueue
        self.payload = payload
        self.accuracy = accuracy
        self.timer = DispatchSource.makeTimerSource(flags: [], queue: timerQueue)
    }
    
    deinit {
        timer.setEventHandler {}
        timer.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        if state == .disarmed {
            timer.resume()
        }
    }
    
    private func scheduleTimer() {
        timer.schedule(deadline: deadline, repeating: .never, leeway: accuracy)
    }
    
    private func fire() {
        executionQueue.async(execute: payload)
    }
    
    func arm() {
        guard state == .disarmed, !timer.isCancelled else { return }
        state = .armed
        scheduleTimer()
        timer.setEventHandler(handler: fire)
        timer.resume()
    }
    
    func reset() {
        guard state == .armed, !timer.isCancelled else { return }
        timer.suspend()
        scheduleTimer()
        timer.resume()
    }

    func disarm() {
        guard state == .armed, !timer.isCancelled else { return }
        state = .disarmed
        timer.suspend()
        timer.setEventHandler {}
    }
}
