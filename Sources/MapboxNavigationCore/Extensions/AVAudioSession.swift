import AVFoundation

extension AVAudioSession {
    // MARK: Adjusting the Volume

    public func tryDuckAudio() -> Error? {
        do {
            try setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .mixWithOthers])
            try setActive(true)
        } catch {
            return error
        }
        return nil
    }

    public func tryUnduckAudio() -> Error? {
        do {
            try setActive(
                false,
                options: [.notifyOthersOnDeactivation]
            )
        } catch {
            return error
        }
        return nil
    }
}
