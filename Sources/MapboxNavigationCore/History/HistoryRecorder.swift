import MapboxNavigationNative

struct HistoryRecorder: HistoryRecording, @unchecked Sendable {
    private let handle: HistoryRecorderHandle

    init(handle: HistoryRecorderHandle) {
        self.handle = handle
    }

    func startRecordingHistory() {
        handle.startRecording()
    }

    func pushHistoryEvent(type: String, jsonData: Data?) {
        let jsonString: String
        if let jsonData {
            guard let value = String(data: jsonData, encoding: .utf8) else {
                assertionFailure("Failed to decode string")
                return
            }
            jsonString = value
        } else {
            jsonString = ""
        }
        Task { @MainActor in
            handle.pushHistory(
                forEventType: type,
                eventJson: jsonString
            )
        }
    }

    func stopRecordingHistory(writingFileWith completionHandler: @escaping HistoryFileWritingCompletionHandler) {
        handle.stopRecording { path in
            if let path {
                completionHandler(URL(fileURLWithPath: path))
            } else {
                completionHandler(nil)
            }
        }
    }
}
