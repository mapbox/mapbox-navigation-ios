@preconcurrency import AVFoundation

struct AudioPlayerClient: Sendable {
    var play: @Sendable (_ url: URL) async throws -> Bool
    var load: @Sendable (_ sounds: [URL]) async throws -> Void
}

@globalActor actor AudioPlayerActor {
    static let shared = AudioPlayerActor()
}

extension AudioPlayerClient {
    @AudioPlayerActor
    static func liveValue() -> AudioPlayerClient {
        let audioActor = AudioActor()
        return Self(
            play: { sound in
                try await audioActor.play(sound: sound)
            },
            load: { sounds in
                try await audioActor.load(sounds: sounds)
            }
        )
    }
}

private actor AudioActor {
    enum Failure: Error {
        case soundIsPlaying(URL)
        case soundNotLoaded(URL)
        case soundsNotLoaded([URL: Error])
    }

    var players: [URL: AVAudioPlayer] = [:]

    func load(sounds: [URL]) throws {
        let sounds = sounds.filter { !players.keys.contains($0) }
        var errors: [URL: Error] = [:]
        for sound in sounds {
            do {
                let player = try AVAudioPlayer(contentsOf: sound)
                players[sound] = player
            } catch {
                errors[sound] = error
            }
        }

        guard errors.isEmpty else {
            throw Failure.soundsNotLoaded(errors)
        }
    }

    func play(sound: URL) async throws -> Bool {
        guard let player = players[sound] else {
            throw Failure.soundNotLoaded(sound)
        }

        guard !player.isPlaying else {
            throw Failure.soundIsPlaying(sound)
        }

        let stream = AsyncThrowingStream<Bool, Error> { continuation in
            let delegate = Delegate(continuation: continuation)
            player.delegate = delegate
            continuation.onTermination = { _ in
                player.stop()
                player.currentTime = 0
                _ = delegate
            }

            player.play()
        }

        return try await stream.first(where: { @Sendable _ in true }) ?? false
    }
}

private final class Delegate: NSObject, AVAudioPlayerDelegate, Sendable {
    let continuation: AsyncThrowingStream<Bool, Error>.Continuation

    init(continuation: AsyncThrowingStream<Bool, Error>.Continuation) {
        self.continuation = continuation
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        continuation.yield(flag)
        continuation.finish()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        continuation.finish(throwing: error)
    }
}
