
enum FeatureIds {
    private static let globalPrefix: String = "com.mapbox.navigation"

    struct RouteLine: Hashable, Sendable {
        private static let prefix: String = "\(globalPrefix).route_line"

        static var main: Self {
            .init(routeId: "\(prefix).main")
        }

        static func alternative(idx: Int) -> Self {
            .init(routeId: "\(prefix).alternative_\(idx)")
        }

        let source: String
        let main: String
        let casing: String

        let restrictedArea: String
        let restrictedAreaSource: String
        let traversedRoute: String

        init(routeId: String) {
            self.source = routeId
            self.main = routeId
            self.casing = "\(routeId).casing"
            self.restrictedArea = "\(routeId).restricted_area"
            self.restrictedAreaSource = "\(routeId).restricted_area"
            self.traversedRoute = "\(routeId).traversed_route"
        }
    }

    struct ManeuverArrow {
        private static let prefix: String = "\(globalPrefix).arrow"

        let id: String
        let symbolId: String
        let arrow: String
        let arrowStroke: String
        let arrowSymbol: String
        let arrowSymbolCasing: String
        let arrowSource: String
        let arrowSymbolSource: String
        let triangleTipImage: String

        init(arrowId: String) {
            let id = "\(Self.prefix).\(arrowId)"
            self.id = id
            self.symbolId = "\(id).symbol"
            self.arrow = "\(id)"
            self.arrowStroke = "\(id).stroke"
            self.arrowSymbol = "\(id).symbol"
            self.arrowSymbolCasing = "\(id).symbol.casing"
            self.arrowSource = "\(id).source"
            self.arrowSymbolSource = "\(id).symbol_source"
            self.triangleTipImage = "\(id).triangle_tip_image"
        }

        static func nextArrow() -> Self {
            .init(arrowId: "next")
        }
    }

    struct VoiceInstruction {
        private static let prefix: String = "\(globalPrefix).voice_instruction"

        let featureId: String
        let source: String
        let layer: String
        let circleLayer: String

        init() {
            let id = "\(Self.prefix)"
            self.featureId = id
            self.source = "\(id).source"
            self.layer = "\(id).layer"
            self.circleLayer = "\(id).layer.circle"
        }

        static var currentRoute: Self {
            .init()
        }
    }

    struct IntersectionAnnotation {
        private static let prefix: String = "\(globalPrefix).intersection_annotations"

        let featureId: String
        let source: String
        let layer: String

        let yieldSignImage: String
        let stopSignImage: String
        let railroadCrossingImage: String
        let trafficSignalImage: String

        init() {
            let id = "\(Self.prefix)"
            self.featureId = id
            self.source = "\(id).source"
            self.layer = "\(id).layer"
            self.yieldSignImage = "\(id).yield_sign"
            self.stopSignImage = "\(id).stop_sign"
            self.railroadCrossingImage = "\(id).railroad_crossing"
            self.trafficSignalImage = "\(id).traffic_signal"
        }

        static var currentRoute: Self {
            .init()
        }
    }

    struct RouteAlertAnnotation {
        private static let prefix: String = "\(globalPrefix).route_alert_annotations"

        let featureId: String
        let source: String
        let layer: String

        init() {
            let id = "\(Self.prefix)"
            self.featureId = id
            self.source = "\(id).source"
            self.layer = "\(id).layer"
        }

        static var `default`: Self {
            .init()
        }
    }

    struct RouteWaypoints {
        private static let prefix: String = "\(globalPrefix)_waypoint"

        let featureId: String
        let innerCircle: String
        let markerIcon: String
        let source: String

        init() {
            self.featureId = "\(Self.prefix).route-waypoints"
            self.innerCircle = "\(Self.prefix).innerCircleLayer"
            self.markerIcon = "\(Self.prefix).symbolLayer"
            self.source = "\(Self.prefix).source"
        }

        static var `default`: Self {
            .init()
        }
    }

    struct RouteAnnotation: Hashable, Sendable {
        private static let prefix: String = "\(globalPrefix).route_line.annotation"
        let layerId: String

        static var main: Self {
            .init(annotationId: "\(prefix).main")
        }

        static func alternative(index: Int) -> Self {
            .init(annotationId: "\(prefix).alternative_\(index)")
        }

        init(annotationId: String) {
            self.layerId = annotationId
        }
    }
}
