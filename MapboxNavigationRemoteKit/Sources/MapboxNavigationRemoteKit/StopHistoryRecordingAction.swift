import Foundation

public struct StopHistoryRecordingAction: Codable {
    public init() {}
}
public struct StopHistoryRecordingResponse: Codable {
    public init(file: HistoryFile?) {
        self.file = file
    }

    public let file: HistoryFile?
}
