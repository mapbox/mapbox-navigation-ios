//
//import Foundation
//
//public protocol SpeechSynthesizer {
//    
//    // MARK: - RouteVoiceController
//    
//    /**
//     If true, a noise indicating the user is going to be rerouted will play prior to rerouting.
//     */
//    public var playRerouteSound = true
//    
//    /**
//     Sound to play prior to reroute. Inherits volume level from `volume`.
//     */
//    public var rerouteSoundPlayer: AVAudioPlayer = try! AVAudioPlayer(data: NSDataAsset(name: "reroute-sound", bundle: .mapboxNavigation)!.data, fileTypeHint: AVFileType.mp3.rawValue)
//    
//    /**
//     Delegate used for getting metadata information about a particular spoken instruction.
//     */
//    public weak var voiceControllerDelegate: VoiceControllerDelegate?
//    
//    /**
//    Default initializer for `RouteVoiceController`.
//    */
//    public init(navigationService: NavigationService)
//    
//    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance)
//    
//    @objc open func didPassSpokenInstructionPoint(notification: NSNotification)
//    
//    /**
//     Reads aloud the given instruction.
//     
//     - parameter instruction: The instruction to read aloud.
//     */
//    open func speak(_ instruction: SpokenInstruction)
//    
//    // MARK: - MapboxVoiceController
//    
//    /**
//     Number of seconds a request can wait before it is canceled and the default speech synthesizer speaks the instruction.
//     */
//    public var timeoutIntervalForRequest: TimeInterval = 5
//    
//    /**
//     Number of steps ahead of the current step to cache spoken instructions.
//     */
//    public var stepsAheadToCache: Int = 3
//    
//    /**
//     An `AVAudioPlayer` through which spoken instructions are played.
//     */
//    public var audioPlayer: AVAudioPlayer?
//    
//    public init(navigationService: NavigationService, speechClient: SpeechSynthesizer = SpeechSynthesizer(accessToken: nil), dataCache: BimodalDataCache = DataCache(), audioPlayerType: AVAudioPlayer.Type? = nil)
//    
//    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
//    
////    open override func didPassSpokenInstructionPoint(notification: NSNotification)
//    
//    /**
//    Speaks an instruction.
//    
//    The cache is first checked to see if we have already downloaded the speech file. If not, the instruction is fetched and played. If there is an error anywhere along the way, the instruction will be spoken with the default speech synthesizer.
//    */
////    open override func speak(_ instruction: SpokenInstruction)
//    
//    /**
//     Speaks an instruction with the built in speech synthesizer.
//     
//     This method should be used in cases where `fetch(instruction:)` or `play(_:)` fails.
//     */
//    open func speakWithDefaultSpeechSynthesizer(_ instruction: SpokenInstruction, error: SpeechError?)
//    
//    /**
//     Fetches and plays an instruction.
//     */
//    open func fetchAndSpeak(instruction: SpokenInstruction)
//    
//    /**
//     Caches an instruction in an in-memory cache.
//     */
//    open func downloadAndCacheSpokenInstruction(instruction: SpokenInstruction)
//    
//    /**
//     Plays an audio file.
//     */
//    open func play(instruction: SpokenInstruction, data: Data)
//}
//
//protocol Usage {
//    
//    // MARK: - RouteVoiceController
//    
//    // -
//    
//    // MARK: - MapboxVoiceController
//    
//    // -
//}
