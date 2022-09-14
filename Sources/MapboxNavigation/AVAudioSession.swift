import AVFoundation

public extension AVAudioSession {
    
    // MARK: Adjusting the Volume
    
    func tryDuckAudio() -> Error? {
        do {
            try setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .mixWithOthers])
            try setActive(true)
        } catch {
            return error
        }
        return nil
    }
    
    func tryUnduckAudio() -> Error? {
        do {
            try setActive(false,
                          options: [.notifyOthersOnDeactivation])
        } catch {
            return error
        }
        return nil
    }
}
