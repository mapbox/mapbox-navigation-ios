@testable import MapboxNavigationCore

extension AudioPlayerClient {
    static var noopValue: AudioPlayerClient {
        Self(
            play: { _ in return false },
            load: { _ in }
        )
    }

    static var testValue: AudioPlayerClient {
        Self(
            play: { _ in
                fatalError("not implemented")
            },
            load: { _ in
                fatalError("not implemented")
            }
        )
    }
}
