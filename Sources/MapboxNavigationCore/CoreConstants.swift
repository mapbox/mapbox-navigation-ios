import Foundation

extension Notification.Name {
    // MARK: Switching Navigation Tile Versions

    /// Posted when Navigator has not enough tiles for map matching on current tiles version, but there are suitable
    /// older versions inside underlying Offline Regions. Navigator has restarted when this notification is issued.
    ///
    /// Such action invalidates all existing matched ``RoadObject`` which should be re-applied manually.
    /// The user info dictionary contains the key ``Navigator/NotificationUserInfoKey/tilesVersionKey``
    @_documentation(visibility: internal)
    public static let navigationDidSwitchToFallbackVersion: Notification
        .Name = .init(rawValue: "NavigatorDidFallbackToOfflineVersion")

    /// Posted when Navigator was switched to a fallback offline tiles version, but latest tiles became available again.
    /// Navigator has restarted when this notification is issued.
    /// Such action invalidates all existing matched ``RoadObject``s which should be re-applied manually.
    /// The user info dictionary contains the key ``NativeNavigator/NotificationUserInfoKey/tilesVersionKey``
    @_documentation(visibility: internal)
    public static let navigationDidSwitchToTargetVersion: Notification
        .Name = .init(rawValue: "NavigatorDidRestoreToOnlineVersion")

    /// Posted when NavNative sends updated navigation status.
    ///
    /// The user info dictionary contains the keys ``Navigator.NotificationUserInfoKey.originKey`` and
    /// ``Navigator/NotificationUserInfoKey/statusKey``.
    static let navigationStatusDidChange: Notification.Name = .init(rawValue: "NavigationStatusDidChange")
}

extension Notification.Name {
    // MARK: Handling Alternative Routes

    static let navigatorDidChangeAlternativeRoutes: Notification
        .Name = .init(rawValue: "NavigatorDidChangeAlternativeRoutes")

    static let navigatorDidFailToChangeAlternativeRoutes: Notification
        .Name = .init(rawValue: "NavigatorDidFailToChangeAlternativeRoutes")

    static let navigatorWantsSwitchToCoincideOnlineRoute: Notification
        .Name = .init(rawValue: "NavigatorWantsSwitchToCoincideOnlineRoute")
}

extension Notification.Name {
    // MARK: Electronic Horizon Notifications

    /// Posted when the user’s position in the electronic horizon changes. This notification may be posted multiple
    /// times after ``Foundation/NSNotification/Name/electronicHorizonDidEnterRoadObject`` until the user transitions to
    /// a new electronic horizon.
    ///
    /// The user info dictionary contains the keys ``RoadGraph/NotificationUserInfoKey/positionKey``,
    /// ``RoadGraph/NotificationUserInfoKey/treeKey``, ``RoadGraph/NotificationUserInfoKey/updatesMostProbablePathKey``,
    /// and ``RoadGraph/NotificationUserInfoKey/distancesByRoadObjectKey``.
    public static let electronicHorizonDidUpdatePosition: Notification.Name =
        .init(rawValue: "ElectronicHorizonDidUpdatePosition")

    /// Posted when the user enters a linear road object.
    ///
    /// The user info dictionary contains the keys ``RoadGraph/NotificationUserInfoKey/roadObjectIdentifierKey`` and
    /// ``RoadGraph/NotificationUserInfoKey/didTransitionAtEndpointKey``.
    public static let electronicHorizonDidEnterRoadObject: Notification.Name =
        .init(rawValue: "ElectronicHorizonDidEnterRoadObject")

    /// Posted when the user exits a linear road object.
    ///
    /// The user info dictionary contains the keys ``RoadGraph/NotificationUserInfoKey/roadObjectIdentifierKey`` and
    /// ``RoadGraph/NotificationUserInfoKey/didTransitionAtEndpointKey``.
    public static let electronicHorizonDidExitRoadObject: Notification.Name =
        .init(rawValue: "ElectronicHorizonDidExitRoadObject")

    /// Posted when user has passed point-like object.
    ///
    /// The user info dictionary contains the key ``RoadGraph/NotificationUserInfoKey/roadObjectIdentifierKey``.
    public static let electronicHorizonDidPassRoadObject: Notification.Name =
        .init(rawValue: "ElectronicHorizonDidPassRoadObject")
}

extension Notification.Name {
    // MARK: Route Refreshing Notifications

    /// Posted when the user’s position in the electronic horizon changes. This notification may be posted multiple
    /// times after ``electronicHorizonDidEnterRoadObject`` until the user transitions to a new electronic horizon.
    ///
    /// The user info dictionary contains the keys ``RoadGraph/NotificationUserInfoKey/positionKey``,
    /// ``RoadGraph/NotificationUserInfoKey/treeKey``, ``RoadGraph/NotificationUserInfoKey/updatesMostProbablePathKey``,
    /// and ``RoadGraph/NotificationUserInfoKey/distancesByRoadObjectKey``.
    static let routeRefreshDidUpdateAnnotations: Notification.Name = .init(rawValue: "RouteRefreshDidUpdateAnnotations")

    /// Posted when the user enters a linear road object.
    ///
    /// The user info dictionary contains the keys ``RoadGraph/NotificationUserInfoKey/roadObjectIdentifierKey`` and
    /// ``RoadGraph/NotificationUserInfoKey/didTransitionAtEndpointKey``.
    static let routeRefreshDidCancelRefresh: Notification.Name = .init(rawValue: "RouteRefreshDidCancelRefresh")

    /// Posted when the user exits a linear road object.
    ///
    /// The user info dictionary contains the keys ``RoadGraph/NotificationUserInfoKey/roadObjectIdentifierKey`` and
    /// ``RoadGraph.NotificationUserInfoKey.transitionKey``.
    static let routeRefreshDidFailRefresh: Notification.Name = .init(rawValue: "RouteRefreshDidFailRefresh")
}

extension NativeNavigator {
    /// Keys in the user info dictionaries of various notifications posted by instances of `NativeNavigator`.
    public struct NotificationUserInfoKey: Hashable, Equatable, RawRepresentable {
        public typealias RawValue = String
        public var rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        static let refreshRequestIdKey: NotificationUserInfoKey = .init(rawValue: "refreshRequestId")
        static let refreshedRoutesResultKey: NotificationUserInfoKey = .init(rawValue: "refreshedRoutesResultKey")
        static let legIndexKey: NotificationUserInfoKey = .init(rawValue: "legIndex")
        static let refreshRequestErrorKey: NotificationUserInfoKey = .init(rawValue: "refreshRequestError")

        ///  A key in the user info dictionary of a
        /// ``Foundation/NSNotification/Name/navigationDidSwitchToFallbackVersion`` or
        /// ``Foundation/NSNotification/Name/navigationDidSwitchToTargetVersion`` notification. The corresponding value
        /// is a string representation of selected tiles version.
        ///
        /// For internal use only.
        @_documentation(visibility: internal)
        public static let tilesVersionKey: NotificationUserInfoKey = .init(rawValue: "tilesVersion")

        static let originKey: NotificationUserInfoKey = .init(rawValue: "origin")

        static let statusKey: NotificationUserInfoKey = .init(rawValue: "status")

        static let alternativesListKey: NotificationUserInfoKey = .init(rawValue: "alternativesList")

        static let removedAlternativesKey: NotificationUserInfoKey = .init(rawValue: "removedAlternatives")

        static let messageKey: NotificationUserInfoKey = .init(rawValue: "message")

        static let coincideOnlineRouteKey: NotificationUserInfoKey = .init(rawValue: "coincideOnlineRoute")
    }
}

extension RoadGraph {
    /// Keys in the user info dictionaries of various notifications posted about ``RoadGraph``s.
    public struct NotificationUserInfoKey: Hashable, Equatable, RawRepresentable, Sendable {
        public typealias RawValue = String
        public var rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        /// A key in the user info dictionary of a ``Foundation/NSNotification/Name/electronicHorizonDidUpdatePosition``
        /// notification. The corresponding value is a ``RoadGraph/Position`` indicating the current position in the
        /// road graph.
        public static let positionKey: NotificationUserInfoKey = .init(rawValue: "position")

        /// A key in the user info dictionary of a ``Foundation/NSNotification/Name/electronicHorizonDidUpdatePosition``
        /// notification. The corresponding value is an ``RoadGraph/Edge`` at the root of a tree of edges in the routing
        /// graph. This graph represents a probable path (or paths) of a vehicle within the routing graph for a certain
        /// distance in front of the vehicle, thus extending the user’s perspective beyond the “visible” horizon as the
        /// vehicle’s position and trajectory change.
        public static let treeKey: NotificationUserInfoKey = .init(rawValue: "tree")

        /// A key in the user info dictionary of a ``Foundation/NSNotification/Name/electronicHorizonDidUpdatePosition``
        /// notification. The corresponding value is a Boolean value of `true` if the position update indicates a new
        /// most probable path (MPP) or `false` if it updates an existing MPP that the user has continued to follow.
        ///
        /// An electronic horizon can represent a new MPP in three scenarios:
        /// - An electronic horizon is detected for the very first time.
        /// - A user location tracking error leads to an MPP completely distinct from the previous MPP.
        /// - The user has departed from the previous MPP, for example by driving to a side path of the previous MPP.
        public static let updatesMostProbablePathKey: NotificationUserInfoKey =
            .init(rawValue: "updatesMostProbablePath")

        /// A key in the user info dictionary of a ``Foundation/NSNotification/Name/electronicHorizonDidUpdatePosition``
        /// notification. The corresponding value is an array of upcoming road object distances from the user’s current
        /// location as ``DistancedRoadObject`` values.
        public static let distancesByRoadObjectKey: NotificationUserInfoKey = .init(rawValue: "distancesByRoadObject")

        /// A key in the user info dictionary of a
        /// ``Foundation/NSNotification/Name/electronicHorizonDidEnterRoadObject`` or
        /// ``Foundation/NSNotification/Name/electronicHorizonDidExitRoadObject`` notification. The corresponding value
        /// is a
        /// ``RoadObject/Identifier`` identifying the road object that the user entered or exited.
        public static let roadObjectIdentifierKey: NotificationUserInfoKey = .init(rawValue: "roadObjectIdentifier")

        /// A key in the user info dictionary of a
        /// ``Foundation/NSNotification/Name/electronicHorizonDidEnterRoadObject`` or
        /// ``Foundation/NSNotification/Name/electronicHorizonDidExitRoadObject`` notification. The corresponding value
        /// is an `NSNumber` containing a Boolean value set to `true` if the user entered at the beginning or exited at
        /// the end of the road object, or `false` if they entered or exited somewhere along the road object.
        public static let didTransitionAtEndpointKey: NotificationUserInfoKey =
            .init(rawValue: "didTransitionAtEndpoint")
    }
}
