struct Environment {
    private(set) static var shared: Environment = .live

    var audioPlayerClient: AudioPlayerClient
    var routerClientProvider: RouterClientProvider
    var routeParserClient: RouteParserClient
    var speechSynthesizerClientProvider: SpeechSynthesizerClientProvider

    static func switchEnvironment(to environment: Environment) {
        shared = environment
    }

    static func set<Value>(_ keyPath: WritableKeyPath<Self, Value>, _ value: Value) {
        shared[keyPath: keyPath] = value
    }
}

extension Environment {
    static let live = Environment(
        audioPlayerClient: .liveValue,
        routerClientProvider: .liveValue,
        routeParserClient: .liveValue,
        speechSynthesizerClientProvider: .liveValue
    )
}
