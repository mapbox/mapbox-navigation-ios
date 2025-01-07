import Foundation
import MapboxCommon
import UIKit

public actor MapboxCopilot {
    public typealias Log = @Sendable (String) -> Void
    public struct Options: Sendable {
        var accessToken: String
        var userId: String = UUID().uuidString
        var navNativeVersion: String
        var sdkVersion: String
        var sdkName: String
        var packageName: String
        var log: (@Sendable (String) -> Void)?

        var sdkInformation: SdkInformation {
            .init(
                name: sdkName,
                version: sdkVersion,
                packageName: packageName
            )
        }

        var feedbackEventsSdkInformation: SdkInformation {
            .init(
                name: "MapboxNavigationNative",
                version: navNativeVersion,
                packageName: nil
            )
        }

        public init(
            accessToken: String,
            userId: String,
            navNativeVersion: String,
            sdkVersion: String,
            sdkName: String,
            packageName: String,
            log: (@Sendable (String) -> Void)? = nil
        ) {
            self.accessToken = accessToken
            self.userId = userId
            self.navNativeVersion = navNativeVersion
            self.sdkVersion = sdkVersion
            self.sdkName = sdkName
            self.log = log
            self.packageName = packageName
        }
    }

    private let eventsController: NavigationHistoryEventsController
    private let manager: NavigationHistoryManager
    private let historyProvider: NavigationHistoryProviderProtocol
    private let options: Options

    public private(set) var currentSession: NavigationSession?

    public func setDelegate(_ delegate: MapboxCopilotDelegate?) {
        self.delegate = delegate
    }

    public private(set) weak var delegate: MapboxCopilotDelegate?

    @MainActor
    public init(
        options: Options,
        historyProvider: NavigationHistoryProviderProtocol
    ) {
        self.init(
            options: options,
            manager: NavigationHistoryManager(
                options: options
            ),
            historyProvider: historyProvider,
            eventsController: NavigationHistoryEventsControllerImpl(
                historyProvider: historyProvider,
                options: options
            )
        )
    }

    init(
        options: Options,
        manager: NavigationHistoryManager,
        historyProvider: NavigationHistoryProviderProtocol,
        eventsController: NavigationHistoryEventsController
    ) {
        self.options = options
        self.manager = manager
        self.historyProvider = historyProvider
        self.eventsController = eventsController

        manager.delegate = self
    }

    @available(*, deprecated, message: """
    Use startActiveGuidanceSessionAsync(requestIdentifier:route:searchResultUsed:) instead. Using the deprecated
    method may lead to losing events in the recorded history files.
    """)
    @discardableResult
    public func startActiveGuidanceSession(
        requestIdentifier: String?,
        route: Encodable,
        searchResultUsed: NavigationHistoryEvents.SearchResultUsed? = nil
    ) throws -> String {
        let session = createActiveGuidanceSession(requestIdentifier: requestIdentifier)
        try startSession(session)
        try eventsController.startActiveGuidanceSession(
            requestIdentifier: requestIdentifier,
            route: route,
            searchResultUsed: searchResultUsed
        )
        return session.id
    }

    @available(*, deprecated, message: """
    Use startFreeDriveSessionAsync() instead. Using the deprecated method may lead to losing events in the recorded
    history files.
    """)
    @discardableResult
    public func startFreeDriveSession() throws -> String {
        let session = createFreeDriveSession()
        try startSession(session)
        eventsController.startFreeDriveSession()
        return session.id
    }

    @available(*, deprecated, message: """
    Use completeNavigationSessionAsync() instead. Using the deprecated method may lead to losing events in the
    recorded history files.
    """)
    public func completeNavigationSession() throws {
        guard let immutableSession = try prepareSessionForCompletion() else { return }

        Task { [weak self] in
            await self?.handleHistoryDump(for: immutableSession)
        }
    }

    @discardableResult
    public func startActiveGuidanceSessionAsync(
        requestIdentifier: String?,
        route: Encodable,
        searchResultUsed: NavigationHistoryEvents.SearchResultUsed? = nil
    ) async throws -> String {
        let session = createActiveGuidanceSession(requestIdentifier: requestIdentifier)
        try await startSessionAsync(session)
        try eventsController.startActiveGuidanceSession(
            requestIdentifier: requestIdentifier,
            route: route,
            searchResultUsed: searchResultUsed
        )
        return session.id
    }

    @discardableResult
    public func startFreeDriveSessionAsync() async throws -> String {
        let session = createFreeDriveSession()
        try await startSessionAsync(session)
        eventsController.startFreeDriveSession()
        return session.id
    }

    @available(*, deprecated, message: "")
    private func startSession(_ session: NavigationSession) throws {
        try completeNavigationSession()
        currentSession = session
        manager.update(session)
        Task {
            await historyProvider.startRecording()
        }
    }

    private func startSessionAsync(_ session: NavigationSession) async throws {
        try await completeNavigationSessionAsync()
        currentSession = session
        manager.update(session)
        await historyProvider.startRecording()
    }

    public func arrive() {
        eventsController.arrive()
    }

    public func completeNavigationSessionAsync() async throws {
        guard let immutableSession = try prepareSessionForCompletion() else { return }
        await handleHistoryDump(for: immutableSession)
    }

    public func reportSearchResults(_ event: NavigationHistoryEvents.SearchResults) throws {
        try eventsController.reportSearchResults(event)
    }

    private func updateSession(
        _ session: inout NavigationSession,
        with result: NavigationHistoryProviderProtocol.DumpResult
    ) {
        var format: NavigationHistoryFormat?
        var errorString: String?
        var fileName: String?
        switch result {
        case .success(let result):
            (fileName, format) = result
        case .failure(.noHistory):
            errorString = "NN provided no history"
            delegate?.copilot(self, didEncounterError: .history(.noHistoryFileProvided, session: session))
        case .failure(.notFound(let path)):
            errorString = "History file provided by NN is not found at '\(path)'"
            delegate?.copilot(self, didEncounterError: .history(.notFound, session: session, userInfo: ["path": path]))
        }
        session.historyFormat = format
        session.historyError = errorString
        session.lastHistoryFileName = fileName
    }
}

extension MapboxCopilot {
    private func createFreeDriveSession() -> NavigationSession {
        NavigationSession(
            sessionType: .freeDrive,
            accessToken: options.accessToken,
            userId: options.userId,
            routeId: nil,
            navNativeVersion: options.navNativeVersion,
            navigationVersion: options.sdkVersion
        )
    }

    private func createActiveGuidanceSession(requestIdentifier: String?) -> NavigationSession {
        NavigationSession(
            sessionType: .activeGuidance,
            accessToken: options.accessToken,
            userId: options.userId,
            routeId: requestIdentifier,
            navNativeVersion: options.navNativeVersion,
            navigationVersion: options.sdkVersion
        )
    }

    private func prepareSessionForCompletion() throws -> NavigationSession? {
        guard var currentSession else { return nil }

        self.currentSession = nil
        currentSession.endedAt = Date()
        manager.update(currentSession)
        try eventsController.completeSession()
        return currentSession
    }

    @MainActor
    private func handleHistoryDump(for immutableSession: NavigationSession) async {
        await historyProvider.dumpHistory { [weak self] dump in
            Task.detached { [weak self, immutableSession] in
                guard let self else { return }
                var currentSession = immutableSession
                await updateSession(&currentSession, with: dump)
                await delegate?.copilot(self, didFinishRecording: currentSession)
                await manager.complete(currentSession)
            }
        }
    }
}

extension MapboxCopilot: NavigationHistoryManagerDelegate {
    nonisolated func historyManager(
        _ historyManager: NavigationHistoryManager,
        didUploadHistoryForSession session: NavigationSession
    ) {
        Task {
            await delegate?.copilot(self, didUploadHistoryFileForSession: session)
        }
    }

    nonisolated func historyManager(_ historyManager: NavigationHistoryManager, didEncounterError error: CopilotError) {
        Task {
            await delegate?.copilot(self, didEncounterError: error)
        }
    }
}
