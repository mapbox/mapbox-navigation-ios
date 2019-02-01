import Foundation
import MapboxCoreNavigation

protocol NavigationCustomizable {
    var styles: [Style]? { get }
    var navigationService: NavigationService? { get }
}
