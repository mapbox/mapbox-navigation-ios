import Foundation
import Dispatch

class CountdownTimer {
    enum State {
        case armed, disarmed
    }
    
    typealias Payload = DispatchSource.DispatchSourceHandler
    static let defaultAccuracy: DispatchTimeInterval = .milliseconds(500)
    let countdownInterval: DispatchTimeInterval
    private var deadline: DispatchTime { return .now() + countdownInterval }
    let accuracy: DispatchTimeInterval
    let payload: Payload
    let queue = DispatchQueue(label: "com.mapbox.coreNavigation.timer.countdown", qos: DispatchQoS.background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
    
    let timer: DispatchSourceTimer
    
    private(set) var state: State = .disarmed
    
    init(countdown: DispatchTimeInterval, payload: @escaping Payload, accuracy: DispatchTimeInterval = defaultAccuracy) {
        countdownInterval = countdown
        self.payload = payload
        self.accuracy = accuracy
        self.timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
    }
    
    deinit {
        timer.setEventHandler {}
        timer.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        timer.resume()
    }
    
    private func scheduleTimer() {
        timer.schedule(deadline: deadline, repeating: .never, leeway: accuracy)
    }
    
    func arm() {
        guard state == .disarmed else { return }
        scheduleTimer()
        timer.setEventHandler(handler: payload)
        timer.resume()
        state = .armed
    }
    
    func reset() {
        guard state == .armed else { return }
        timer.cancel()
        scheduleTimer()
        timer.resume()
    }

    func disarm() {
        guard state == .armed else { return }
        timer.cancel()
        timer.setEventHandler {}
        state = .disarmed
    }
}
