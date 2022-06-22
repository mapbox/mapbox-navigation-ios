import MapboxNavigationNative


class HistoryRecorder {
    /**
     Path to the directory where history file could be stored when `HistoryRecording.stopRecordingHistory(writingFileWith:)` is called.
     
     Setting `nil` disables history recording. Defaults to `nil`. Updating value from `nil` to `non-nil` value results in recreating the shared instance since `nil` guaranteed an invalid handler. Further updates have no effect.
     */
    static var historyDirectoryURL: URL? = nil
    {
        didSet {
            if _historyRecorder?.handle == nil && historyDirectoryURL != nil {
                _historyRecorder = nil
            } else if oldValue != nil {
                Log.warning("`historyDirectoryURL` is updated excessively.", category: .settings)
            }
        }
    }
    
    /**
     The shared instance
     */
    static var shared: HistoryRecorder {
        guard let historyRecorder = _historyRecorder else {
            let historyRecorder = HistoryRecorder()
            _historyRecorder = historyRecorder
            return historyRecorder
        }
        return historyRecorder
    }

    /// `True` when `HistoryRecorder.shared` requested at least once.
    static var isSharedInstanceCreated: Bool {
        _historyRecorder != nil
    }
    
    // Used in tests to recreate the history recorder
    static func _recreateHistoryRecorder() { _historyRecorder = nil }
    
    private static var _historyRecorder: HistoryRecorder?
    
    private(set) var handle: HistoryRecorderHandle? = nil
    
    private init() {
        Self.historyDirectoryURL.flatMap {
            handle = HistoryRecorderHandle.build(forHistoryDir: $0.path,
                                                 config: NativeHandlersFactory.configHandle())
        }
    }
}
