import AVFoundation
import Foundation
import MapboxDirections

extension SpokenInstruction {
    func attributedText(for legProgress: RouteLegProgress) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(string: text)
        if let step = legProgress.upcomingStep,
           let name = step.names?.first,
           let phoneticName = step.phoneticNames?.first
        {
            let nameRange = attributedText.mutableString.range(of: name)
            if nameRange.location != NSNotFound {
                attributedText.replaceCharacters(
                    in: nameRange,
                    with: NSAttributedString(string: name).pronounced(phoneticName)
                )
            }
        }
        if let step = legProgress.followOnStep,
           let name = step.names?.first,
           let phoneticName = step.phoneticNames?.first
        {
            let nameRange = attributedText.mutableString.range(of: name)
            if nameRange.location != NSNotFound {
                attributedText.replaceCharacters(
                    in: nameRange,
                    with: NSAttributedString(string: name).pronounced(phoneticName)
                )
            }
        }
        return attributedText
    }
}

extension NSAttributedString {
    public func pronounced(_ pronunciation: String) -> NSAttributedString {
        let phoneticWords = pronunciation.components(separatedBy: " ")
        let phoneticString = NSMutableAttributedString()
        for (word, phoneticWord) in zip(string.components(separatedBy: " "), phoneticWords) {
            // AVSpeechSynthesizer doesn’t recognize some common IPA symbols.
            let phoneticWord = phoneticWord.byReplacing([("ɡ", "g"), ("ɹ", "r")])
            if phoneticString.length > 0 {
                phoneticString.append(NSAttributedString(string: " "))
            }
            phoneticString.append(NSAttributedString(string: word, attributes: [
                NSAttributedString.Key(rawValue: AVSpeechSynthesisIPANotationAttribute): phoneticWord,
            ]))
        }
        return phoneticString
    }
}
