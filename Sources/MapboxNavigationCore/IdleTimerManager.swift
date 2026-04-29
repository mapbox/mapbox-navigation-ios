import _MapboxNavigationHelpers
import Foundation
import UIKit

/// An idle timer which is managed by `IdleTimerManager`.
protocol IdleTimer: Sendable {
    func setDisabled(_ disabled: Bool)
}

/// UIApplication specific idle timer.
struct UIApplicationIdleTimer: IdleTimer {
    func setDisabled(_ disabled: Bool) {
        // Using @MainActor task is unsafe as order of Tasks is undefined. DispatchQueue.main is easiest solution.
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = disabled
        }
    }
}

/// Manages `UIApplication.shared.isIdleTimerDisabled`.
public final class IdleTimerManager: Sendable {
    private typealias ID = String

    /// While a cancellable isn't cancelled, the idle timer is disabled. A cancellable is cancelled on deallocation.
    public final class Cancellable: Sendable {
        private let onCancel: @Sendable () -> Void

        fileprivate init(_ onCancel: @escaping @Sendable () -> Void) {
            self.onCancel = onCancel
        }

        deinit {
            onCancel()
        }
    }

    public static let shared: IdleTimerManager = .init(idleTimer: UIApplicationIdleTimer())

    private let idleTimer: IdleTimer

    /// Number of currently non cancelled `IdleTimerManager.Cancellable` instances.
    private let cancellablesCount: UnfairLocked<Int> = .init(0)

    private let idleTokens: UnfairLocked<[ID: Cancellable]> = .init([:])

    init(idleTimer: IdleTimer) {
        self.idleTimer = idleTimer
    }

    /// Disables idle timer `UIApplication.shared.isIdleTimerDisabled` while there is at least one non-cancelled
    /// `IdleTimerManager.Cancellable` instance.
    /// - Returns: An instance of cancellable that you should retain until you want the idle timer to be disabled.
    public func disableIdleTimer() -> IdleTimerManager.Cancellable {
        let cancellable = Cancellable {
            self.changeCancellabelsCount(delta: -1)
        }
        changeCancellabelsCount(delta: 1)
        return cancellable
    }

    /// Disables the idle timer with the specified id.
    /// - Parameter id: The id of the timer to disable.
    public func disableIdleTimer(id: String) {
        idleTokens.mutate {
            $0[id] = disableIdleTimer()
        }
    }

    /// Enables the idle timer with the specified id.
    /// - Parameter id: The id of the timer to enable.
    public func enableIdleTimer(id: String) {
        idleTokens.mutate {
            $0[id] = nil
        }
    }

    private func changeCancellabelsCount(delta: Int) {
        let isIdleTimerDisabled = cancellablesCount.mutate {
            $0 += delta
            return $0 > 0
        }
        idleTimer.setDisabled(isIdleTimerDisabled)
    }
}
