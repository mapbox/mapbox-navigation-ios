import CoreLocation
import Foundation

public struct NavigationSession: Codable, Equatable, @unchecked Sendable {
    public enum SessionType: String, Codable {
        case activeGuidance = "active_guidance"
        case freeDrive = "free_drive"
    }

    public enum State: String, Codable {
        case inProgress = "in_progress"
        case local
        case uploading
    }

    public let id: String
    public let startedAt: Date
    public let userId: String
    public internal(set) var sessionType: SessionType
    public internal(set) var accessToken: String
    public internal(set) var state: State
    public internal(set) var routeId: String?
    public internal(set) var endedAt: Date?
    public internal(set) var historyError: String?
    public internal(set) var appMode: String
    public internal(set) var appVersion: String
    public internal(set) var navigationSdkVersion: String
    public internal(set) var navigationNativeSdkVersion: String
    public internal(set) var tokenOwner: String?
    public internal(set) var appSessionId: String
    var lastHistoryFileName: String?
    var historyFormat: NavigationHistoryFormat?

    init(
        sessionType: SessionType,
        accessToken: String,
        userId: String,
        routeId: String?,
        navNativeVersion: String,
        navigationVersion: String
    ) {
        self.id = UUID().uuidString
        self.sessionType = sessionType
        self.userId = userId
        self.routeId = routeId
        self.accessToken = accessToken

        self.startedAt = Date()
        self.tokenOwner = TokenOwnerProvider.owner(of: accessToken)
        self.appMode = AppEnvironment.applicationMode
        self.appVersion = AppEnvironment.hostApplicationVersion()
        self.navigationSdkVersion = navigationVersion
        self.navigationNativeSdkVersion = navNativeVersion
        self.state = .inProgress
        self.appSessionId = AppEnvironment.applicationSessionId
    }
}

extension NavigationSession {
    @_spi(MapboxInternal) public var _lastHistoryFileName: String? { lastHistoryFileName }
}

extension NavigationSession {
    var lastHistoryFileUrl: URL? {
        guard let lastHistoryFileName, lastHistoryFileName.isEmpty == false else {
            return nil
        }
        return URL(string: lastHistoryFileName)
    }

    func deleteLastHistoryFile() throws {
        guard let url = lastHistoryFileUrl else { return }
        try FileManager.default.removeItem(at: url)
    }
}
