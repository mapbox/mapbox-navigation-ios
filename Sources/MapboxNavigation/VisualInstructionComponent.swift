import UIKit
import MapboxDirections

extension VisualInstruction.Component {
    static let scale = UIScreen.main.scale
    
    var cacheKey: String? {
        switch self {
        case let .exit(representation), let .exitCode(representation):
            let exitCode = representation.text
            return "exit-" + exitCode + "-\(VisualInstruction.Component.scale)"
        case let .image(imageRepresentation, alternativeText):
            return imageRepresentation.legacyCacheKey ?? "generic-" + alternativeText.text
        case .text, .delimiter, .lane:
            return nil
        case .guidanceView(let guidanceViewRepresentation, _):
            guard let imageURL = guidanceViewRepresentation.imageURL else { return nil }
            return "guidance-" + imageURL.absoluteString
        }
    }
}

extension VisualInstruction.Component.ImageRepresentation {
    var legacyCacheKey: String? {
        guard let key = imageBaseURL?.absoluteString else { return nil }
        return "\(key)-\(VisualInstruction.Component.scale)"
    }
}
