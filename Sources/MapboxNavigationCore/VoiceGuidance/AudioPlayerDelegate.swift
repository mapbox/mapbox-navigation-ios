import AVFAudio

@MainActor
final class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    var onAudioPlayerDidFinishPlaying: (@MainActor (AVAudioPlayer, _ didFinishSuccessfully: Bool) -> Void)?
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        MainActor.assumingIsolated {
            onAudioPlayerDidFinishPlaying?(player, flag)
        }
    }
}
