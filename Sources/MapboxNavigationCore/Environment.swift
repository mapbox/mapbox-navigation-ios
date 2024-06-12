struct Environment: Sendable {
    var audioPlayerClient: AudioPlayerClient
}

extension Environment {
    @AudioPlayerActor
    static let live = Environment(
        audioPlayerClient: .liveValue()
    )
}

@AudioPlayerActor
var Current = Environment.live
