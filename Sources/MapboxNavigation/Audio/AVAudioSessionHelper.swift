import AVFAudio

/// AVAudioSessionHelper is a thread-safe class for synchronizing `AVFAudio/AVAudioSession` activations and deactivations.
///
/// All actions to activate/deactivate audio session should go through `AVAudioSessionHelper`.
///
/// It is recommended to use `deferredUnduckAudio(delayBy:)` for audio session deactivation in case
/// activations/deactivations can occur in quick succesion (like when playing voice instructions, alert sounds, etc.) to avoid unnecessary deactivations.

final class AVAudioSessionHelper {
    static let defaultDeferredUnduckDelay: TimeInterval = 1.0
    static let shared = AVAudioSessionHelper()
    private let syncQueue = DispatchQueue(label: "AVAudioSessionHelper.syncQueue")
    private var deactivationWorkItem: DispatchWorkItem?
    let settings: Settings = Settings(
        category: .playback,
        mode: .voicePrompt,
        options: [.duckOthers, .mixWithOthers]
    )
    
    private init() {}
    
    func duckAudio(completion: ((Result<Void, Error>) -> Void)?) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            self.cancelDeactivationWorkItem()
            Log.debug("AVAudioSessionHelper: Activating AVAudioSession...", category: .audio)
            do {
                try AVAudioSessionHelper.activateAudioSession(settings: self.settings)
                Log.debug("AVAudioSessionHelper: AVAudioSession Activated", category: .audio)
                completion?(.success(()))
            } catch {
                completion?(.failure(error))
            }
        }
    }
    
    func unduckAudio(completion: ((Result<Void, Error>) -> Void)?) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            self.cancelDeactivationWorkItem()
            Log.debug("AVAudioSessionHelper: Deactivating AVAudioSession...", category: .audio)
            do {
                try AVAudioSessionHelper.deactivateAudioSession()
                Log.debug("AVAudioSessionHelper: AVAudioSession Deactivated", category: .audio)
                completion?(.success(()))
            } catch {
                completion?(.failure(error))
            }
        }
    }
    
    @discardableResult
    func deferredUnduckAudio(delayBy deactivationDelay: TimeInterval = AVAudioSessionHelper.defaultDeferredUnduckDelay) -> Bool {
        if deactivationDelay <= 0 {
            assertionFailure("Delay must be positive")
            return true
        }
        return syncQueue.sync {
            if self.deactivationWorkItem != nil {
                return false
            }
            Log.debug("AVAudioSessionHelper: Scheduling Deferred Deactivation of AVAudioSession... (delay: \(deactivationDelay))", category: .audio)
            
            var workItem: DispatchWorkItem!
            workItem = DispatchWorkItem { [weak self, weak workItem] in
                guard let self = self else { return }
                self.deactivationWorkItem = nil
                
                if workItem?.isCancelled ?? false {
                    Log.debug("AVAudioSessionHelper: Deactivation (Scheduled) work item Cancelled", category: .audio)
                    return
                }
                
                Log.debug("AVAudioSessionHelper: Deactivating AVAudioSession... (Scheduled)", category: .audio)
                do {
                    try AVAudioSessionHelper.deactivateAudioSession()
                    Log.debug("AVAudioSessionHelper: AVAudioSession Deactivated (Scheduled)", category: .audio)
                } catch {
                    Log.warning("AVAudioSessionHelper: Exception thrown while executing Deactivate AVAudioSession (Scheduled): \(error)", category: .audio)
                }
            }
            
            self.deactivationWorkItem = workItem
            self.syncQueue.asyncAfter(deadline: .now() + deactivationDelay, execute: workItem)
            return true
        }
    }
    
    private func cancelDeactivationWorkItem() {
        if let workItem = self.deactivationWorkItem {
            workItem.cancel()
            self.deactivationWorkItem = nil
        }
    }
    
    private static func activateAudioSession(settings: Settings) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(settings.category, mode: settings.mode, options: settings.options)
        try session.setActive(true)
    }
    
    private static func deactivateAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setActive(false, options: [.notifyOthersOnDeactivation])
    }
}

extension AVAudioSessionHelper {
    struct Settings {
        var category: AVAudioSession.Category
        var mode: AVAudioSession.Mode
        var options: AVAudioSession.CategoryOptions
    }
}
