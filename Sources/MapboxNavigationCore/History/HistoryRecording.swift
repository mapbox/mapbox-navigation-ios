import Foundation

/// Types that conform to this protocol record low-level details as the user goes through a trip for debugging purposes.
public protocol HistoryRecording: Sendable {
    /// A closure to be called when history writing ends.
    /// - Parameters:
    ///   - historyFileURL: A URL to the file that contains history data. This argument is `nil` if no history data has
    /// been written because history recording has not yet begun. Use the
    /// ``HistoryRecording/startRecordingHistory()`` method to begin recording before attempting to write a history
    /// file.
    typealias HistoryFileWritingCompletionHandler = @Sendable (_ historyFileURL: URL?) -> Void

    /// Starts recording history for debugging purposes.
    ///
    /// - Postcondition: Use the ``HistoryRecording/stopRecordingHistory(writingFileWith:)`` method to stop recording
    /// history and write the recorded history to a file.
    @MainActor
    func startRecordingHistory()

    /// Appends a custom event to the current history log. This can be useful to log things that happen during
    /// navigation that are specific to your application.
    /// - Parameters:
    ///   - type: The event type in the events log for your custom event.
    ///   - jsonData: The data value that contains a valid JSON to attach to the event.
    func pushHistoryEvent(type: String, jsonData: Data?)

    /// Stops recording history, asynchronously writing any recorded history to a file.
    ///
    /// Upon completion, the completion handler is called with the URL to a file in the directory specified by
    /// ``HistoryRecordingConfig/historyDirectoryURL``. The file contains details about the passive location manager’s
    /// activity that may be  useful to include when reporting an issue to Mapbox.
    /// - Precondition: Use the ``HistoryRecording/startRecordingHistory()`` method to begin recording history. If the
    /// ``HistoryRecording/startRecordingHistory()`` method has not been called, this method has no effect.
    /// - Postcondition: To write history incrementally without an interruption in history recording, use the
    /// ``HistoryRecording/startRecordingHistory()`` method immediately after this method. If you use the
    /// ``HistoryRecording/startRecordingHistory()`` method inside the completion handler of this method, history
    /// recording will be paused while the file is being prepared.
    /// - Parameter completionHandler: A closure to be executed when the history file is ready.
    @MainActor
    func stopRecordingHistory(writingFileWith completionHandler: @escaping HistoryFileWritingCompletionHandler)
}

/// Convenience methods for ``HistoryRecording`` protocol.
extension HistoryRecording {
    /// Appends a custom event to the current history log. This can be useful to log things that happen during
    /// navigation that are specific to your application.
    /// - Precondition: Use the ``HistoryRecording/startRecordingHistory()`` method to begin recording history. If the
    /// ``HistoryRecording/startRecordingHistory()`` method has not been called, this method has no effect.
    /// - Parameters:
    ///   - type: The event type in the events log for your custom event.
    ///   - value: The value that implements `Encodable` protocol and can be encoded into a valid JSON to attach to the
    /// event.
    ///   - encoder: The instance of `JSONEncoder` to be used for the value encoding. If this argument is omitted, the
    /// default `JSONEncoder` will be used.
    public func pushHistoryEvent(type: String, value: (some Encodable)?, encoder: JSONEncoder? = nil) throws {
        let data = try value.map { value -> Data in
            try (encoder ?? JSONEncoder()).encode(value)
        }
        pushHistoryEvent(type: type, jsonData: data)
    }

    /// Appends a custom event to the current history log. This can be useful to log things that happen during
    /// navigation that are specific to your application.
    /// - Precondition: Use the ``HistoryRecording/startRecordingHistory()`` method to begin recording history. If the
    /// ``HistoryRecording/startRecordingHistory()`` method has not been called, this method has no effect.
    /// - Parameters:
    ///   - type: The event type in the events log for your custom event.
    ///   - value: The value disctionary that can be encoded into a JSON to attach to the event.
    public func pushHistoryEvent(type: String, dictionary value: [String: Any?]?) throws {
        let data = try value.map { value -> Data in
            try JSONSerialization.data(withJSONObject: value, options: [])
        }
        pushHistoryEvent(type: type, jsonData: data)
    }
}
