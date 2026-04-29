import _MapboxNavigationHelpers
import UIKit

final class EventAppState: Sendable {
    struct Environment {
        let date: @Sendable () -> Date
        let applicationState: @Sendable () -> UIApplication.State
        let screenOrientation: @Sendable () -> UIDeviceOrientation
        let deviceOrientation: @Sendable () -> UIDeviceOrientation

        static var live: Self {
            .init(
                date: { Date() },
                applicationState: {
                    onMainQueueSync {
                        UIApplication.shared.applicationState
                    }
                },
                screenOrientation: {
                    onMainQueueSync {
                        UIDevice.current.screenOrientation
                    }
                },
                deviceOrientation: {
                    onMainQueueSync {
                        UIDevice.current.orientation
                    }
                }
            )
        }
    }

    private let environment: Environment
    private let innerState: UnfairLocked<State>
    private let sessionStarted: Date

    private struct State {
        var timeSpentInPortrait: TimeInterval = 0
        var lastOrientation: UIDeviceOrientation
        var lastTimeOrientationChanged: Date

        var timeInBackground: TimeInterval = 0
        var lastTimeEnteredBackground: Date?
    }

    var percentTimeInForeground: Int {
        let state = innerState.read()
        let currentDate = environment.date()
        var totalTimeInBackground = state.timeInBackground
        if let lastTimeEnteredBackground = state.lastTimeEnteredBackground {
            totalTimeInBackground += currentDate.timeIntervalSince(lastTimeEnteredBackground)
        }

        let totalTime = currentDate.timeIntervalSince(sessionStarted)
        return totalTime > 0 ? Int(100 * (totalTime - totalTimeInBackground) / totalTime) : 100
    }

    var percentTimeInPortrait: Int {
        let state = innerState.read()
        let currentDate = environment.date()
        var totalTimeInPortrait = state.timeSpentInPortrait
        if state.lastOrientation.isPortrait {
            totalTimeInPortrait += currentDate.timeIntervalSince(state.lastTimeOrientationChanged)
        }

        let totalTime = currentDate.timeIntervalSince(sessionStarted)
        return totalTime > 0 ? Int(100 * totalTimeInPortrait / totalTime) : 100
    }

    @MainActor
    init(environment: Environment = .live) {
        self.environment = environment

        let date = environment.date()
        self.sessionStarted = date
        let lastOrientation = environment.screenOrientation()
        let lastTimeOrientationChanged = date
        let lastTimeEnteredBackground: Date? = environment.applicationState() == .background ? date : nil
        let innerState = State(
            lastOrientation: lastOrientation,
            lastTimeOrientationChanged: lastTimeOrientationChanged,
            lastTimeEnteredBackground: lastTimeEnteredBackground
        )
        self.innerState = .init(innerState)

        subscribeNotifications()
    }

    // MARK: - State Management

    private func subscribeNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForegroundState),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackgroundState),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didChangeOrientation),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    @objc
    private func didChangeOrientation() {
        handleOrientationChange()
    }

    @objc
    private func didEnterBackgroundState() {
        let date = environment.date()
        innerState.mutate {
            $0.lastTimeEnteredBackground = date
        }
    }

    @objc
    private func willEnterForegroundState() {
        let state = innerState.read()
        guard let dateEnteredBackground = state.lastTimeEnteredBackground else { return }

        let timeDelta = environment.date().timeIntervalSince(dateEnteredBackground)
        innerState.mutate {
            $0.timeInBackground += timeDelta
            $0.lastTimeEnteredBackground = nil
        }
    }

    private func handleOrientationChange() {
        let state = innerState.read()
        let orientation = environment.deviceOrientation()
        guard orientation.isValidInterfaceOrientation else { return }
        guard state.lastOrientation.isPortrait != orientation.isPortrait ||
            state.lastOrientation.isLandscape != orientation.isLandscape else { return }

        let currentDate = environment.date()
        let timePortraitDelta = orientation.isLandscape ? currentDate
            .timeIntervalSince(state.lastTimeOrientationChanged) : 0
        innerState.mutate {
            $0.timeSpentInPortrait += timePortraitDelta
            $0.lastTimeOrientationChanged = currentDate
            $0.lastOrientation = orientation
        }
    }
}
