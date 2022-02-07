import Foundation

/**
 Types that conform to this protocol record low-level details as the user goes through a trip for debugging purposes.
 */
public protocol HistoryRecording {
    /**
     A closure to be called when history writing ends.

     - parameter historyFileURL: A URL to the file that contains history data. This argument is `nil` if no history data has been written because history recording has not yet begun. Use the `startRecordingHistory()` method to begin recording before attempting to write a history file.
     */
    typealias HistoryFileWritingCompletionHandler = (_ historyFileURL: URL?) -> Void

    /**
     Path to the directory where history file could be stored when `stopRecordingHistory(writingFileWith:)` is called.

     Setting `nil` disables history recording. Defaults to `nil`.
     */
    static var historyDirectoryURL: URL? { get set }

    /**
     Starts recording history for debugging purposes.

     - postcondition: Use the `stopRecordingHistory(writingFileWith:)` method to stop recording history and write the recorded history to a file.
     */
    static func startRecordingHistory()

    /**
     Appends a custom event to the current history log. This can be useful to log things that happen during navigation that are specific to your application.

     - parameter type: The event type in the events log for your custom event.
     - parameter jsonData: The data value that contains a valid JSON to attach to the event.

     - precondition: Use the `startRecordingHistory()` method to begin recording history. If the `startRecordingHistory()` method has not been called, this method has no effect.
     */
    static func pushHistoryEvent(type: String, jsonData: Data?) throws

    /**
     Stops recording history, asynchronously writing any recorded history to a file.

     Upon completion, the completion handler is called with the URL to a file in the directory specified by `historyDirectoryURL`. The file contains details about the passive location manager’s activity that may be useful to include when reporting an issue to Mapbox.

     - precondition: Use the `startRecordingHistory()` method to begin recording history. If the `startRecordingHistory()` method has not been called, this method has no effect.
     - postcondition: To write history incrementally without an interruption in history recording, use the `startRecordingHistory()` method immediately after this method. If you use the `startRecordingHistory()` method inside the completion handler of this method, history recording will be paused while the file is being prepared.

     - parameter completionHandler: A closure to be executed when the history file is ready.
     */
    static func stopRecordingHistory(writingFileWith completionHandler: @escaping HistoryFileWritingCompletionHandler)
}

/*
 The default implementation of `HistoryRecording` protocol.
 */
public extension HistoryRecording {
    static var historyDirectoryURL: URL? {
        get {
            Navigator.historyDirectoryURL
        }
        set {
            Navigator.historyDirectoryURL = newValue
        }
    }

    static func startRecordingHistory() {
        if Navigator.isSharedInstanceCreated {
            Navigator.shared.historyRecorder?.startRecording()
        }
    }

    static func pushHistoryEvent(type: String, jsonData: Data?) throws {
        var jsonString: String?
        if let jsonData = jsonData {
            guard let value = String(data: jsonData, encoding: .utf8) else {
                assertionFailure("Failed to decode string")
                return
            }
            jsonString = value
        }
        if Navigator.isSharedInstanceCreated {
            Navigator.shared.historyRecorder?.pushHistory(forEventType: type, eventJson: jsonString ?? "")
        }
    }

    static func stopRecordingHistory(writingFileWith completionHandler: @escaping HistoryFileWritingCompletionHandler) {
        guard Navigator.isSharedInstanceCreated,
              let historyRecorder = Navigator.shared.historyRecorder else {
            completionHandler(nil)
            return
        }
        historyRecorder.stopRecording { (path) in
            if let path = path {
                completionHandler(URL(fileURLWithPath: path))
            } else {
                completionHandler(nil)
            }
        }
    }
}

/*
 Convenience methods for `HistoryRecording` protocol.
 */
public extension HistoryRecording {
    /**
     Appends a custom event to the current history log. This can be useful to log things that happen during navigation that are specific to your application.

     - parameter type: The event type in the events log for your custom event.
     - parameter value: The value that implements `Encodable` protocol and can be encoded into a valid JSON to attach to the event.
     - parameter encoder: The instance of `JSONEncoder` to be used for the value encoding. If this argument is omitted, the default `JSONEncoder` will be used.

     - precondition: Use the `startRecordingHistory()` method to begin recording history. If the `startRecordingHistory()` method has not been called, this method has no effect.
     */
    static func pushHistoryEvent<Value: Encodable>(type: String, value: Value?, encoder: JSONEncoder? = nil) throws {
        let data = try value.map { value -> Data in
            try (encoder ?? JSONEncoder()).encode(value)
        }
        try pushHistoryEvent(type: type, jsonData: data)
    }

    /**
     Appends a custom event to the current history log. This can be useful to log things that happen during navigation that are specific to your application.

     - parameter type: The event type in the events log for your custom event.
     - parameter value: The value disctionary that can be encoded into a JSON to attach to the event.

     - precondition: Use the `startRecordingHistory()` method to begin recording history. If the `startRecordingHistory()` method has not been called, this method has no effect.
     */
    static func pushHistoryEvent(type: String, dictionary value: [String: Any?]?) throws {
        let data = try value.map { value -> Data in
            try JSONSerialization.data(withJSONObject: value, options: [])
        }
        try pushHistoryEvent(type: type, jsonData: data)
    }
}
