import Foundation
import MapboxCoreNavigation
import CoreLocation

/*
 A NavigationComponent is any component that can receive NavigationService messages.
 */
@objc public protocol NavigationComponent: NavigationServiceDelegate/*, UIContentContainer*/ {}
