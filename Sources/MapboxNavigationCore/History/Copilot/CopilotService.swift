import Foundation
import MapboxNavigationNative
import UIKit

public actor CopilotService {
    private final class HistoryProviderAdapter: NavigationHistoryProviderProtocol, @unchecked Sendable {
        private let historyRecording: HistoryRecording

        init(_ historyRecording: HistoryRecording) {
            self.historyRecording = historyRecording
        }

        func startRecording() {
            historyRecording.startRecordingHistory()
        }

        func pushEvent(event: some NavigationHistoryEvent) throws {
            try historyRecording.pushHistoryEvent(type: event.eventType, value: event.payload)
        }

        func dumpHistory(_ completion: @escaping @Sendable (DumpResult) -> Void) {
            historyRecording.stopRecordingHistory(writingFileWith: { url in
                guard let url else {
                    completion(.failure(.noHistory))
                    return
                }
                completion(.success((url.absoluteString, .protobuf)))
            })
        }
    }

    public private(set) var mapboxCopilot: MapboxCopilot?

    public func setActive(_ isActive: Bool) {
        self.isActive = isActive
    }

    public private(set) var isActive: Bool {
        get {
            mapboxCopilot != nil
        }
        set {
            switch (newValue, mapboxCopilot) {
            case (true, .none):
                activateCopilot()
            case (false, .some):
                mapboxCopilot = nil
            default:
                break
            }
        }
    }

    private let accessToken: String
    private let navNativeVersion: String
    private let historyRecording: HistoryRecording
    private let log: (@Sendable (String) -> Void)?
    public func setDelegate(_ delegate: MapboxCopilotDelegate) {
        self.delegate = delegate
    }

    public private(set) weak var delegate: MapboxCopilotDelegate?

    private func activateCopilot() {
        Task {
            mapboxCopilot = await MapboxCopilot(
                options: MapboxCopilot.Options(
                    accessToken: accessToken,
                    userId: UIDevice.current.identifierForVendor?.uuidString ?? "-",
                    navNativeVersion: navNativeVersion,
                    sdkVersion: Bundle.mapboxNavigationVersion,
                    sdkName: Bundle.resolvedNavigationSDKName,
                    packageName: Bundle.mapboxNavigationUXBundleIdentifier,
                    log: log
                ),
                historyProvider: HistoryProviderAdapter(historyRecording)
            )
            await mapboxCopilot?.setDelegate(delegate)
        }
    }

    public init(
        accessToken: String,
        navNativeVersion: String,
        historyRecording: HistoryRecording,
        isActive: Bool = true,
        log: (@Sendable (String) -> Void)? = nil
    ) {
        self.accessToken = accessToken
        self.navNativeVersion = navNativeVersion
        self.historyRecording = historyRecording
        self.log = log
        defer {
            Task {
                await self.setActive(isActive)
            }
        }
    }
}
