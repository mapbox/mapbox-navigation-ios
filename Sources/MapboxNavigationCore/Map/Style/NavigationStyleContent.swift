import MapboxMaps

enum NavigationSlot {
    static let aboveBasemap = Slot(rawValue: "navigation-above-basemap")!
}

/// The navigation declarative map style content.
public struct NavigationStyleContent: MapStyleContent {
    var routeLines: [FeatureIds.RouteLine: RouteLineStyleContent] = [:]
    var waypoints: WaypointsLineStyleContent?
    var maneuverArrow: ManeuverArrowStyleContent?
    var routeAlert: RouteAlertsStyleContent?
    var intersectionAnnotations: IntersectionAnnotationsStyleContent?
    var voiceInstruction: VoiceInstructionsTextStyleContent?

    var customRoutePosition: LayerPosition? {
        didSet {
            for key in routeLines.keys {
                routeLines[key]?.customPosition = customRoutePosition
            }
            maneuverArrow?.customPosition = customRoutePosition
        }
    }

    /// Provides the navigation style content.
    public var body: some MapStyleContent {
        if let customRoutePosition {
            if !routeLines.isEmpty {
                SlotLayer(id: RouteLineStyleContent.customSlotName)
                    .position(customRoutePosition)
            }
        } else if let middle = Slot.middle {
            SlotLayer(id: middle.rawValue)
        }

        if let content = routeLines[.alternative(idx: 0)] {
            content
        }
        if let content = routeLines[.alternative(idx: 1)] {
            content
        }
        if let content = routeLines[.main] {
            content
        }

        if let maneuverArrow {
            maneuverArrow
        }

        if let voiceInstruction {
            voiceInstruction
        }

        SlotLayer(id: NavigationSlot.aboveBasemap.rawValue)

        if let intersectionAnnotations {
            intersectionAnnotations
        }

        if let routeAlert {
            routeAlert
        }

        if let waypoints {
            waypoints
        }
    }
}
