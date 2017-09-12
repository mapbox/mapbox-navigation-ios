import Foundation

extension String {
    
    enum ConjunctionRule {
        case none
        case succeedingAIsound
    }
    
    static func localizedConjunction(lhs: String, rhs: String, rule: ConjunctionRule = .none) -> String {
        switch rule {
        case .none:
            return String.localizedStringWithFormat(NSLocalizedString("CONJUNCTION_FORMAT", bundle: .mapboxNavigation, value: "%@ and %@", comment: "Format for displaying a conjunction of two words or phrases"), lhs, rhs)
        case .succeedingAIsound:
            if let char = rhs.first, char.isPronouncedAI {
                return String.localizedStringWithFormat(NSLocalizedString("CONJUNCTION_SUCCEEDING_AI_SOUND_FORMAT", bundle: .mapboxNavigation, value: "%@ and %@", comment: "Format for displaying two words or phrases where the right hand side starts with an AI sound"), lhs, rhs)
            }
            
            return String.localizedStringWithFormat(NSLocalizedString("CONJUNCTION_FORMAT", bundle: .mapboxNavigation, value: "%@ and %@", comment: "Format for displaying a conjunction of two words or phrases"), lhs, rhs)
        }
    }
}

extension Character {
    var isPronouncedAI: Bool {
        return ["i", "y"].contains(Character(String(self).lowercased()))
    }
}
