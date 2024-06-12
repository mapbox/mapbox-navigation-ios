import Foundation

/**
 Types that conform to this protocol record low-level details as the user goes through a trip for debugging purposes.
 */
public protocol HistoryRecording: Sendable {
    /**
     A closure to be called when history writing ends.

     - parameter historyFileURL: A URL to the file that contains history data. This argument is `nil` if no history data has been written because history recording has not yet begun. Use the `startRecordingHistory()` method to begin recording before attempting to write a history file.
     */
    typealias HistoryFileWritingCompletionHandler = @Sendable (_ historyFileURL: URL?) -> Void

    /**
     Starts recording history for debugging purposes.

     - postcondition: Use the `stopRecordingHistory(writingFileWith:)` method to stop recording history and write the recorded history to a file.
     */
    func startRecordingHistory()

    /**
     Appends a custom event to the current history log. This can be useful to log things that happen during navigation that are specific to your application.

     - parameter type: The event type in the events log for your custom event.
     - parameter jsonData: The data value that contains a valid JSON to attach to the event.

     - precondition: Use the `startRecordingHistory()` method to begin recording history. If the `startRecordingHistory()` method has not been called, this method has no effect.
     */
    func pushHistoryEvent(type: String, jsonData: Data?)

    /**
     Stops recording history, asynchronously writing any recorded history to a file.

     Upon completion, the completion handler is called with the URL to a file in the directory specified by `historyDirectoryURL`. The file contains details about the passive location manager’s activity that may be useful to include when reporting an issue to Mapbox.

     - precondition: Use the `startRecordingHistory()` method to begin recording history. If the `startRecordingHistory()` method has not been called, this method has no effect.
     - postcondition: To write history incrementally without an interruption in history recording, use the `startRecordingHistory()` method immediately after this method. If you use the `startRecordingHistory()` method inside the completion handler of this method, history recording will be paused while the file is being prepared.

     - parameter completionHandler: A closure to be executed when the history file is ready.
     */
    func stopRecordingHistory(writingFileWith completionHandler: @escaping HistoryFileWritingCompletionHandler)
}

/*
 Convenience methods for `HistoryRecording` protocol.
 */
extension HistoryRecording {
    /**
     Appends a custom event to the current history log. This can be useful to log things that happen during navigation that are specific to your application.

     - parameter type: The event type in the events log for your custom event.
     - parameter value: The value that implements `Encodable` protocol and can be encoded into a valid JSON to attach to the event.
     - parameter encoder: The instance of `JSONEncoder` to be used for the value encoding. If this argument is omitted, the default `JSONEncoder` will be used.

     - precondition: Use the `startRecordingHistory()` method to begin recording history. If the `startRecordingHistory()` method has not been called, this method has no effect.
     */
    public func pushHistoryEvent(type: String, value: (some Encodable)?, encoder: JSONEncoder? = nil) throws {
        let data = try value.map { value -> Data in
            try (encoder ?? JSONEncoder()).encode(value)
        }
        pushHistoryEvent(type: type, jsonData: data)
    }

    /**
     Appends a custom event to the current history log. This can be useful to log things that happen during navigation that are specific to your application.

     - parameter type: The event type in the events log for your custom event.
     - parameter value: The value disctionary that can be encoded into a JSON to attach to the event.

     - precondition: Use the `startRecordingHistory()` method to begin recording history. If the `startRecordingHistory()` method has not been called, this method has no effect.
     */
    public func pushHistoryEvent(type: String, dictionary value: [String: Any?]?) throws {
        let data = try value.map { value -> Data in
            try JSONSerialization.data(withJSONObject: value, options: [])
        }
        pushHistoryEvent(type: type, jsonData: data)
    }
}
