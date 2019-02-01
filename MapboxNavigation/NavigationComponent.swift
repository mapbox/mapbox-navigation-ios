import Foundation
import MapboxCoreNavigation
import CoreLocation

/*
 A NavigationComponent is any component that can receive NavigationServiceDelegate messages.
 */
@objc public protocol NavigationComponent: NavigationServiceDelegate {}
