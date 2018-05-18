import UIKit
import MapboxDirections

extension VisualInstructionComponent {
    
    static let scale = UIScreen.main.scale
    
    func cacheKey() -> String? {
        switch type {
        case .exit, .exitCode:
            guard let exitCode = self.text else { return nil}
            return "exit-" + exitCode + "-\(VisualInstructionComponent.scale)-\(hashValue)"
        case .image:
            guard let imageURL = imageURL else { return genericCacheKey() }
            return "\(imageURL.absoluteString)-\(VisualInstructionComponent.scale)"
        default:
            return nil
        }
    }
    
    func genericCacheKey() -> String {
        return "generic-" + (text ?? "nil")
    }
}
