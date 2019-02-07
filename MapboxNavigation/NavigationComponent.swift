import Foundation
import MapboxCoreNavigation
import CoreLocation

/*
 A navigation component is a member of the navigation UI view hierarchy that responds as the user progresses along a route according to the `NavigationServiceDelegate` protocol.
 */
@objc public protocol NavigationComponent: NavigationServiceDelegate {}
