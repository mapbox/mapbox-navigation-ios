import Foundation
import Dispatch

/**
 `DispatchTimer` is a general-purpose wrapper over the `DispatchSourceTimer` mechanism in GCD.
 */
public class DispatchTimer {
    /**
     The state of a `DispatchTimer`.
     */
    public enum State {
        /**
         Timer is active and has an event scheduled.
         */
        case armed
        /**
         Timer is idle
         */
        case disarmed
    }
    
    public typealias Payload = DispatchSource.DispatchSourceHandler
    public static let defaultAccuracy: DispatchTimeInterval = .milliseconds(500)
    
    /**
     Timer current state.
     */
    private(set) public var state: State = .disarmed
    
    var countdownInterval: DispatchTimeInterval {
        didSet {
            reset()
        }
    }
    private var deadline: DispatchTime { return .now() + countdownInterval }
    let repetitionInterval: DispatchTimeInterval
    let accuracy: DispatchTimeInterval
    let payload: Payload
    let timerQueue = DispatchQueue(label: "com.mapbox.coreNavigation.timer")
    let executionQueue: DispatchQueue
    let timer: DispatchSourceTimer
    
    /**
     Initializes a new timer.
     
     - parameter countdown: The initial time interval for the timer to wait before firing off the payload for the first time.
     - parameter repeating: The subsequent time interval for the timer to wait before firing off the payload an additional time. Repeats until manually stopped.
     - parameter accuracy: The amount of leeway, expressed as a time interval, that the timer has in it's timing of the payload execution. Default is 500 milliseconds.
     - parameter executingOn: the queue on which the timer executes. Default is main queue.
     - parameter payload: The payload that executes when the timer expires.
     */
    public init(countdown: DispatchTimeInterval, repeating repetition: DispatchTimeInterval = .never, accuracy: DispatchTimeInterval = defaultAccuracy, executingOn executionQueue: DispatchQueue = .main, payload: @escaping Payload) {
        countdownInterval = countdown
        repetitionInterval = repetition
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
    
    /**
     Arm the timer. Countdown will begin after this function returns.
     */
    public func arm() {
        guard state == .disarmed, !timer.isCancelled else { return }
        state = .armed
        scheduleTimer()
        timer.setEventHandler { [weak self] in
            if let unwrappedSelf = self {
                unwrappedSelf.executionQueue.async(execute: unwrappedSelf.payload)
            }
        }
        timer.resume()
    }
    
    /**
     Re-arm the timer. Countdown will restart after this function returns.
     */
    public func reset() {
        guard state == .armed, !timer.isCancelled else { return }
        timer.suspend()
        scheduleTimer()
        timer.resume()
    }

    /**
     Disarm the timer. Countdown will stop after this function returns.
     */
    public func disarm() {
        guard state == .armed, !timer.isCancelled else { return }
        state = .disarmed
        timer.suspend()
        timer.setEventHandler {}
    }
    
    private func scheduleTimer() {
        timer.schedule(deadline: deadline, repeating: repetitionInterval, leeway: accuracy)
    }
}
