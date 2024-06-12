import Foundation

public struct HistoryRecordingConfig: Equatable, Sendable {
    public static let defaultFolderName = "historyRecordings"

    public var historyDirectoryURL: URL

    public init(
        historyDirectoryURL: URL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent(defaultFolderName)
    ) {
        self.historyDirectoryURL = historyDirectoryURL
    }
}
