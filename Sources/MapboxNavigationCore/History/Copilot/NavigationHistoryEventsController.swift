import Combine
import Foundation
import UIKit

protocol NavigationHistoryEventsController {
    func startActiveGuidanceSession(
        requestIdentifier: String?,
        route: Encodable,
        searchResultUsed: NavigationHistoryEvents.SearchResultUsed?
    ) throws
    func startFreeDriveSession()
    func arrive()
    func completeSession() throws

    func reportSearchResults(_ event: NavigationHistoryEvents.SearchResults) throws
    func resetSearchResults()
}

final class NavigationHistoryEventsControllerImpl: NavigationHistoryEventsController {
    private let historyProvider: NavigationHistoryProviderProtocol
    private let feedbackEventsObserver: FeedbackEventsObserver
    private let timeProvider: () -> TimeInterval

    private var sessionStartTimestamp: TimeInterval?
    private var arrived = false
    private var lastSearchResultsEvent: NavigationHistoryEvents.SearchResults?

    private var lifetimeSubscriptions = Set<AnyCancellable>()

    @MainActor
    init(
        historyProvider: NavigationHistoryProviderProtocol,
        options: MapboxCopilot.Options,
        feedbackEventsObserver: FeedbackEventsObserver? = nil,
        timeProvider: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) {
        self.historyProvider = historyProvider
        self.feedbackEventsObserver = feedbackEventsObserver ?? FeedbackEventsObserverImpl(
            options: options
        )
        self.timeProvider = timeProvider

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        self.feedbackEventsObserver.navigationFeedbackPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                try? historyProvider.pushEvent(event: $0)
            }
            .store(in: &lifetimeSubscriptions)
    }

    func startActiveGuidanceSession(
        requestIdentifier: String?,
        route: Encodable,
        searchResultUsed: NavigationHistoryEvents.SearchResultUsed?
    ) throws {
        resetSession()
        if let event = NavigationHistoryEvents.InitRoute(
            requestIdentifier: requestIdentifier,
            route: route
        ) {
            try? historyProvider.pushEvent(event: event)
        }
        try lastSearchResultsEvent.flatMap { try historyProvider.pushEvent(event: $0) }
        try searchResultUsed.flatMap { try historyProvider.pushEvent(event: $0) }
    }

    func startFreeDriveSession() {
        resetSession()
    }

    private func resetSession() {
        sessionStartTimestamp = timeProvider()
        arrived = false
        feedbackEventsObserver.refreshSubscription()
    }

    func arrive() {
        arrived = true
    }

    func completeSession() throws {
        if let sessionStartTimestamp {
            let duration = timeProvider() - sessionStartTimestamp
            self.sessionStartTimestamp = nil
            try historyProvider.pushEvent(event: NavigationHistoryEvents.DriveEnds(payload: .init(
                type: arrived ? .arrived : .canceledManually,
                realDuration: Int(duration * 1e3)
            )))
        }
    }

    func reportSearchResults(_ event: NavigationHistoryEvents.SearchResults) throws {
        lastSearchResultsEvent = event
        try historyProvider.pushEvent(event: event)
    }

    func resetSearchResults() {
        lastSearchResultsEvent = nil
    }

    // MARK: - Notifications

    @objc
    private func applicationDidEnterBackground() {
        try? historyProvider.pushEvent(event: NavigationHistoryEvents.ApplicationState.goingToBackground)
    }

    @objc
    private func applicationWillEnterForeground() {
        try? historyProvider.pushEvent(event: NavigationHistoryEvents.ApplicationState.goingToForeground)
    }
}
