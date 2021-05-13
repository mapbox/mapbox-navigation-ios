import Foundation
import CarPlay

extension UIScreen {
    static var mainCarPlay: UIScreen? {
        return UIScreen.screens.filter { $0.traitCollection.containsTraits(in: UITraitCollection(userInterfaceIdiom: .carPlay)) }.first
    }
}
