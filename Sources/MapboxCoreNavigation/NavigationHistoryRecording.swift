import Foundation

/**
 Recording History to Diagnose Problems
 */
public protocol NavigationHistoryRecording {
    /**
     A closure to be called when history writing ends.

     - parameter historyFileURL: A URL to the file that contains history data. This argument is `nil` if no history data has been written because history recording has not yet begun. Use the `startRecordingHistory()` method to begin recording before attempting to write a history file.
     */
    typealias HistoryFileWritingCompletionHandler = (_ historyFileURL: URL?) -> Void

    /**
     Path to the directory where history could be stored when `PassiveLocationManager.writeHistory(completionHandler:)` is called.
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
     - parameter jsonString: The string value that contains a valid JSON to attach to the event.

     - precondition: Use the `startRecordingHistory()` method to begin recording history. If the `startRecordingHistory()` method has not been called, this method has no effect.
     */
    static func pushHistoryEvent(type: String, jsonString: String?)

    /**
     Stops recording history, asynchronously writing any recorded history to a file.

     Upon completion, the completion handler is called with the URL to a file in the directory specified by `PassiveLocationManager.historyDirectoryURL`. The file contains details about the passive location manager’s activity that may be useful to include when reporting an issue to Mapbox.

     - precondition: Use the `startRecordingHistory()` method to begin recording history. If the `startRecordingHistory()` method has not been called, this method has no effect.
     - postcondition: To write history incrementally without an interruption in history recording, use the `startRecordingHistory()` method immediately after this method. If you use the `startRecordingHistory()` method inside the completion handler of this method, history recording will be paused while the file is being prepared.

     - parameter completionHandler: A closure to be executed when the history file is ready.
     */
    static func stopRecordingHistory(writingFileWith completionHandler: @escaping HistoryFileWritingCompletionHandler)
}

/*
 The default implementation of `NavigationHistoryRecording` protocol.
 */
public extension NavigationHistoryRecording {
    static var historyDirectoryURL: URL? {
        get {
            Navigator.historyDirectoryURL
        }
        set {
            Navigator.historyDirectoryURL = newValue
        }
    }

    static func startRecordingHistory() {
        Navigator.shared.startRecordingHistory()
    }

    static func pushHistoryEvent(type: String, jsonString: String?) {
        Navigator.shared.pushHistoryEvent(type: type, jsonString: jsonString)
    }

    static func stopRecordingHistory(writingFileWith completionHandler: @escaping HistoryFileWritingCompletionHandler) {
        Navigator.shared.stopRecordingHistory(writingFileWith: completionHandler)
    }
}

public extension NavigationHistoryRecording {
    /**
     Appends a custom event to the current history log. This can be useful to log things that happen during navigation that are specific to your application.

     - parameter type: The event type in the events log for your custom event.
     - parameter value: The value that implements `Encodable` protocol and can be encoded into a valid JSON to attach to the event.

     - precondition: Use the `startRecordingHistory()` method to begin recording history. If the `startRecordingHistory()` method has not been called, this method has no effect.
     */
    static func pushHistoryEvent<Value: Encodable>(type: String, value: Value? = nil) {
        let jsonString: String?
        if let value = value {
            guard let data = try? JSONEncoder().encode(value),
                  let string = String(data: data, encoding: .utf8)
            else {
                assertionFailure("Failed to serialize value")
                return
            }
            jsonString = string
        } else {
            jsonString = nil
        }
        pushHistoryEvent(type: type, jsonString: jsonString)
    }

    /**
     Appends a custom event to the current history log. This can be useful to log things that happen during navigation that are specific to your application.

     - parameter type: The event type in the events log for your custom event.
     - parameter value: The value disctionary that can be encoded into a JSON to attach to the event.

     - precondition: Use the `startRecordingHistory()` method to begin recording history. If the `startRecordingHistory()` method has not been called, this method has no effect.
     */
    static func pushHistoryEvent(type: String, dictionary value: [String: Any?]? = nil) {
        let jsonString: String?
        if let value = value {
            guard let data = try? JSONSerialization.data(withJSONObject: value, options: []),
                  let string = String(data: data, encoding: .utf8)
            else {
                assertionFailure("Failed to serialize value")
                return
            }
            jsonString = string
        } else {
            jsonString = nil
        }
        pushHistoryEvent(type: type, jsonString: jsonString)
    }
}
