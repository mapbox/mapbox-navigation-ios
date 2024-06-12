import Foundation

public enum TextType: String, Codable, Sendable, Hashable {
    case text
    case ssml
}

public enum AudioFormat: String, Codable, Sendable, Hashable {
    case mp3
}

public enum SpeechGender: String, Codable, Sendable, Hashable {
    case female
    case male
    case neuter
}

public struct SpeechOptions: Codable, Sendable, Equatable {
    public init(
        text: String,
        locale: Locale
    ) {
        self.text = text
        self.locale = locale
        self.textType = .text
    }

    public init(
        ssml: String,
        locale: Locale
    ) {
        self.text = ssml
        self.locale = locale
        self.textType = .ssml
    }

    /// `String` to create audiofile for. Can either be plain text or
    /// [`SSML`](https://en.wikipedia.org/wiki/Speech_Synthesis_Markup_Language).
    ///
    /// If `SSML` is provided, `TextType` must be ``TextType/ssml``.
    public var text: String

    /// Type of text to synthesize.
    ///
    /// `SSML` text must be valid `SSML` for request to work.
    public let textType: TextType

    /// Audio format for outputted audio file.
    public var outputFormat: AudioFormat = .mp3

    /// The locale in which the audio is spoken.
    ///
    /// By default, the user's system locale will be used to decide upon an appropriate voice.
    public var locale: Locale

    /// Gender of voice speaking text.
    ///
    /// - Note: not all languages have male and female voices.
    public var speechGender: SpeechGender = .neuter

    /// The path of the request URL, not including the hostname or any parameters.
    var path: String {
        var characterSet = CharacterSet.urlPathAllowed
        characterSet.remove(charactersIn: "/")
        return "voice/v1/speak/\(text.addingPercentEncoding(withAllowedCharacters: characterSet)!)"
    }

    /// An array of URL parameters to include in the request URL.
    var params: [URLQueryItem] {
        var params: [URLQueryItem] = [
            URLQueryItem(name: "textType", value: String(describing: textType)),
            URLQueryItem(name: "language", value: locale.identifier),
            URLQueryItem(name: "outputFormat", value: String(describing: outputFormat)),
        ]

        if speechGender != .neuter {
            params.append(URLQueryItem(name: "gender", value: String(describing: speechGender)))
        }

        return params
    }
}
