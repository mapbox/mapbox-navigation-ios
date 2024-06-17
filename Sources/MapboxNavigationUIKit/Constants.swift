import CoreLocation
import Foundation
import MapboxDirections

extension Notification.Name {
    /// Posted when ``StyleManager`` applies a style that was triggered by change of time of day, or when entering or
    /// exiting a tunnel.
    ///
    /// This notification is the equivalent of ``StyleManagerDelegate/styleManager(_:didApply:)``.
    /// The user info dictionary contains the key ``StyleManagerNotificationUserInfoKey/styleKey`` and
    /// ``StyleManagerNotificationUserInfoKey/styleManagerKey``.
    public static let styleManagerDidApplyStyle: Notification.Name = .init(rawValue: "StyleManagerDidApplyStyle")
}

/// Keys in the user info dictionaries of various notifications posted by instances of ``StyleManager``.
public struct StyleManagerNotificationUserInfoKey: Hashable, Equatable, RawRepresentable {
    public typealias RawValue = String

    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// A key in the user info dictionary of ``Foundation/NSNotification/Name/styleManagerDidApplyStyle`` notification.
    /// The corresponding value is an ``Style`` instance that was applied.
    public static let styleKey: StyleManagerNotificationUserInfoKey = .init(rawValue: "style")

    /// A key in the user info dictionary of ``Foundation/NSNotification/Name/styleManagerDidApplyStyle`` notification.
    /// The corresponding value is an ``StyleManager`` instance that applied the style.
    public static let styleManagerKey: StyleManagerNotificationUserInfoKey = .init(rawValue: "styleManager")
}

//// Dictionary, which contains any custom user info related data on CarPlay (for example it's used by `CPTrip`, while
/// filling it with `CPRouteChoice` objects or for storing user information in `CPListItem`).
///
/// In case if `CPRouteChoice`, `CPListItem` or other ``CarPlayUserInfo`` dependant object uses different type in
/// `userInfo` it may lead to undefined behavior.
public typealias CarPlayUserInfo = [String: Any?]

/// In case if distance to the next maneuver on the route is lower than the value defined in
/// ``InstructionCardHighlightDistance``, ``InstructionsCardView``'s background color will be highlighted to a color
/// defined in ``InstructionsCardContainerView/highlightedBackgroundColor``.
let InstructionCardHighlightDistance: CLLocationDistance = 152.4 // 500 ft
