import UIKit

final class EventAppState {
    struct Environment {
        let date: () -> Date
        let applicationState: () -> UIApplication.State
        let screenOrientation: () -> UIDeviceOrientation
        let deviceOrientation: () -> UIDeviceOrientation

        static var live: Self {
            .init(date: { Date() },
                  applicationState: { UIApplication.shared.applicationState },
                  screenOrientation: { UIDevice.current.screenOrientation },
                  deviceOrientation: { UIDevice.current.orientation })
        }
    }
    private let environment: Environment

    private(set) var timeSpentInPortrait: TimeInterval = 0
    private(set) var lastOrientation: UIDeviceOrientation
    private(set) var lastTimeOrientationChanged: Date

    private(set) var timeInBackground: TimeInterval = 0
    private(set) var lastTimeEnteredBackground: Date?

    private(set) var sessionStarted: Date

    var percentTimeInForeground: Int {
        let currentDate = environment.date()
        var totalTimeInBackground = timeInBackground
        if let lastTimeEnteredBackground = lastTimeEnteredBackground {
            totalTimeInBackground += currentDate.timeIntervalSince(lastTimeEnteredBackground)
        }

        let totalTime = currentDate.timeIntervalSince(sessionStarted)
        return totalTime > 0 ? Int(100 * (totalTime - totalTimeInBackground) / totalTime) : 100
    }

    var percentTimeInPortrait: Int {
        let currentDate = environment.date()
        var totalTimeInPortrait = timeSpentInPortrait
        if lastOrientation.isPortrait {
            totalTimeInPortrait += currentDate.timeIntervalSince(lastTimeOrientationChanged)
        }

        let totalTime = currentDate.timeIntervalSince(sessionStarted)
        return totalTime > 0 ? Int(100 * totalTimeInPortrait / totalTime) : 100
    }

    init(environment: Environment = .live) {
        self.environment = environment
        self.lastOrientation = environment.screenOrientation()

        let date = environment.date()
        lastTimeOrientationChanged = date
        sessionStarted = date

        if environment.applicationState() == .background {
            self.lastTimeEnteredBackground = date
        }

        subscribeNotifications()
    }

    //MARK: - State Management

    private func subscribeNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForegroundState),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackgroundState),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didChangeOrientation),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    @objc private func didChangeOrientation() {
        handleOrientationChange()
    }

    @objc private func didEnterBackgroundState() {
        lastTimeEnteredBackground = environment.date()
    }

    @objc private func willEnterForegroundState() {
        guard let dateEnteredBackground = lastTimeEnteredBackground else { return }

        timeInBackground += environment.date().timeIntervalSince(dateEnteredBackground)
        lastTimeEnteredBackground = nil
    }

    private func handleOrientationChange() {
        let orientation = environment.deviceOrientation()
        guard orientation.isValidInterfaceOrientation else { return }
        guard lastOrientation.isPortrait != orientation.isPortrait ||
        lastOrientation.isLandscape != orientation.isLandscape else { return }

        let currentDate = environment.date()
        if orientation.isLandscape {
            timeSpentInPortrait += currentDate.timeIntervalSince(lastTimeOrientationChanged)
        }
        lastTimeOrientationChanged = currentDate
        lastOrientation = orientation
    }

}
