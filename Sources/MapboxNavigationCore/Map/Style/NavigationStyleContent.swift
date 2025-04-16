import MapboxMaps

struct NavigationStyleContent: MapStyleContent {
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

    var body: some MapStyleContent {
        if let customRoutePosition, !routeLines.isEmpty {
            SlotLayer(id: RouteLineStyleContent.customSlotName)
                .position(customRoutePosition)
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
