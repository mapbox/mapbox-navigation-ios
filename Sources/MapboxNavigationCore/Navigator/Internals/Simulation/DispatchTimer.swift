import Dispatch
import Foundation

/// `DispatchTimer` is a general-purpose wrapper over the `DispatchSourceTimer` mechanism in GCD.
class DispatchTimer {
    /// The state of a `DispatchTimer`.
    enum State {
        /// Timer is active and has an event scheduled.
        case armed
        /// Timer is idle.
        case disarmed
    }

    typealias Payload = @Sendable () -> Void
    static let defaultAccuracy: DispatchTimeInterval = .milliseconds(500)

    /// Timer current state.
    private(set) var state: State = .disarmed

    var countdownInterval: DispatchTimeInterval {
        didSet {
            reset()
        }
    }

    private var deadline: DispatchTime { return .now() + countdownInterval }
    let repetitionInterval: DispatchTimeInterval
    let accuracy: DispatchTimeInterval
    let payload: Payload
    let timerQueue = DispatchQueue(label: "com.mapbox.SimulatedLocationManager.Timer")
    let executionQueue: DispatchQueue
    let timer: DispatchSourceTimer

    /// Initializes a new timer.
    /// - Parameters:
    ///   - countdown: The initial time interval for the timer to wait before firing off the payload for the first time.
    ///   - repetition: The subsequent time interval for the timer to wait before firing off the payload an additional
    /// time. Repeats until manually stopped.
    ///   - accuracy: The amount of leeway, expressed as a time interval, that the timer has in it's timing of the
    /// payload execution. Default is 500 milliseconds.
    ///   - executionQueue: The queue on which the timer executes. Default is main queue.
    ///   - payload: The payload that executes when the timer expires.
    init(
        countdown: DispatchTimeInterval,
        repeating repetition: DispatchTimeInterval = .never,
        accuracy: DispatchTimeInterval = defaultAccuracy,
        executingOn executionQueue: DispatchQueue = .main,
        payload: @escaping Payload
    ) {
        self.countdownInterval = countdown
        self.repetitionInterval = repetition
        self.executionQueue = executionQueue
        self.payload = payload
        self.accuracy = accuracy
        self.timer = DispatchSource.makeTimerSource(flags: [], queue: timerQueue)
    }

    deinit {
        timer.setEventHandler {}
        timer.cancel()
        // If the timer is suspended, calling cancel without resuming triggers a crash. This is documented here
        // https://forums.developer.apple.com/thread/15902
        if state == .disarmed {
            timer.resume()
        }
    }

    /// Arm the timer. Countdown will begin after this function returns.
    func arm() {
        guard state == .disarmed, !timer.isCancelled else { return }
        state = .armed
        scheduleTimer()
        timer.setEventHandler { [weak self] in
            if let unwrappedSelf = self {
                let payload = unwrappedSelf.payload
                unwrappedSelf.executionQueue.async(execute: payload)
            }
        }
        timer.resume()
    }

    /// Re-arm the timer. Countdown will restart after this function returns.
    func reset() {
        guard state == .armed, !timer.isCancelled else { return }
        timer.suspend()
        scheduleTimer()
        timer.resume()
    }

    /// Disarm the timer. Countdown will stop after this function returns.
    func disarm() {
        guard state == .armed, !timer.isCancelled else { return }
        state = .disarmed
        timer.suspend()
        timer.setEventHandler {}
    }

    private func scheduleTimer() {
        timer.schedule(deadline: deadline, repeating: repetitionInterval, leeway: accuracy)
    }
}
