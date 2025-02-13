import AVFAudio

/// The purpose of this actor is to synchronize `AVFAudio/AVAudioSession` activations and deactivations.
///
/// All actions to activate/deactivate audio session should go through `AVAudioSessionHelper`.
///
/// It is recommended to use `deferredUnduckAudio(delayBy:)` for audio session deactivation in case
/// activations/deactivations
/// can occur in quick succesion (like when playing voice instructions, alert sounds, etc.) to avoid unnecessary
/// deactivations.
///
/// **Note:** This actor needs further work if other playback categories/modes/options would need to be used.
/// Currently this helper is designed to facilitate playback of voice instructions and alert sounds.
actor AVAudioSessionHelper {
    private static let defaultDeferredUnduckDelay: TimeInterval = 1
    private var deactivationTask: Task<Void, Error>?

    static let shared = AVAudioSessionHelper()
    private init() {}

    let settings = Settings(
        category: .playback,
        mode: .voicePrompt,
        options: [.duckOthers, .mixWithOthers]
    )

    func duckAudio() async throws {
        Log.debug("AVAudioSessionHelper: Activating AVAudioSession...", category: .audio)
        if let deactivationTask {
            deactivationTask.cancel()
            self.deactivationTask = nil
        }
        try activateAudioSesssion(settings: settings)
        Log.debug("AVAudioSessionHelper: AVAudioSession Activated", category: .audio)
    }

    func unduckAudio() async throws {
        Log.debug("AVAudioSessionHelper: Deactivating AVAudioSession...", category: .audio)
        if let deactivationTask {
            deactivationTask.cancel()
            self.deactivationTask = nil
        }
        try deactivateAudioSesssion()
        Log.debug("AVAudioSessionHelper: AVAudioSession Deactivated", category: .audio)
    }

    @discardableResult
    func deferredUnduckAudio(delayBy deactivationDelay: TimeInterval = defaultDeferredUnduckDelay) async -> Bool {
        guard deactivationTask == nil else {
            return false
        }

        guard deactivationDelay > 0 else {
            assertionFailure("Delay must be positive")
            return true
        }

        Log.debug(
            "AVAudioSessionHelper: Scheduling Deferred Deactivation of AVAudioSession... (delay: \(deactivationDelay))",
            category: .audio
        )
        deactivationTask = Task {
            defer {
                self.deactivationTask = nil
            }

            do {
                try await Task.sleep(nanoseconds: UInt64(deactivationDelay * Double(NSEC_PER_SEC)))
            } catch {
                Log.debug("AVAudioSessionHelper: Deactivation (Scheduled) task Cancelled", category: .audio)
                throw error
            }

            do {
                Log.debug("Deactivating AVAudioSession... (Scheduled)", category: .audio)
                try deactivateAudioSesssion()
                Log.debug("AVAudioSessionHelper: AVAudioSession Deactivated (Scheduled)", category: .audio)
            } catch {
                // An exception here does not necessarily mean that the audio session failed to deactivate.
                // It may be thrown if setActive(false) is called while some sound is still playing,
                // but the session can still be deactivated according to Apple's documentation.
                Log.warning(
                    "AVAudioSessionHelper: Exception thrown while executing Deactivate AVAudioSession (Scheduled): \(error)",
                    category: .audio
                )
            }
        }
        return true
    }

    private func cancelDeactivationTask() {
        if let deactivationTask {
            deactivationTask.cancel()
            self.deactivationTask = nil
        }
    }
}

extension AVAudioSessionHelper {
    struct Settings {
        var category: AVAudioSession.Category
        var mode: AVAudioSession.Mode
        var options: AVAudioSession.CategoryOptions
    }
}

@inline(__always)
private func activateAudioSesssion(settings: AVAudioSessionHelper.Settings) throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(settings.category, mode: settings.mode, options: settings.options)
    try session.setActive(true)
}

@inline(__always)
private func deactivateAudioSesssion() throws {
    let session = AVAudioSession.sharedInstance()
    try session.setActive(false, options: [.notifyOthersOnDeactivation])
}
