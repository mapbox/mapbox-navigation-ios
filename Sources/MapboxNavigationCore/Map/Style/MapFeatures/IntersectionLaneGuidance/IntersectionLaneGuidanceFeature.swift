import Foundation
import MapboxDirections
import MapboxMaps

struct IntersectionLaneGuidanceData: Equatable {
    let point: Point
    let approachLanes: [LaneIndication]
    let preferredApproachLanes: IndexSet?
    let usableApproachLanes: IndexSet?
    let usableLaneIndication: ManeuverDirection?
}

struct IntersectionLaneGuidanceFeature: MapFeature {
    var id: String

    private let viewAnnotations: [ViewAnnotation]

    init?(
        state: [IntersectionLaneGuidanceData],
        featureId: String,
        mapStyleConfig: MapStyleConfig
    ) {
        guard state.isEmpty == false else { return nil }

        self.id = featureId
        var annotations: [ViewAnnotation] = []

        for laneGuidanceData in state {
            let calloutView = LaneGuidanceCalloutView(
                laneGuidanceData: laneGuidanceData,
                mapStyleConfig: mapStyleConfig
            )
            let viewAnnotation = ViewAnnotation(annotatedFeature: .geometry(laneGuidanceData.point), view: calloutView)
            annotations.append(viewAnnotation)
        }

        annotations.forEach {
            guard let calloutView = $0.view as? LaneGuidanceCalloutView else { return }
            $0.setup(with: calloutView)
        }
        self.viewAnnotations = annotations
    }

    func add(to mapView: MapboxMaps.MapView, order: inout MapLayersOrder) {
        for annotation in viewAnnotations {
            mapView.viewAnnotations.add(annotation)
        }
    }

    func remove(from mapView: MapboxMaps.MapView, order: inout MapLayersOrder) {
        viewAnnotations.forEach { $0.remove() }
    }

    func update(oldValue: any MapFeature, in mapView: MapboxMaps.MapView, order: inout MapLayersOrder) {
        oldValue.remove(from: mapView, order: &order)
        add(to: mapView, order: &order)
    }
}

extension ViewAnnotation {
    fileprivate func setup(with calloutView: LaneGuidanceCalloutView) {
        ignoreCameraPadding = true
        allowOverlapWithPuck = true
        onAnchorChanged = { config in
            calloutView.anchor = config.anchor
        }

        let routeCalloutAnchors: [ViewAnnotationAnchor] = [
            .bottomLeft, .bottomRight, .topLeft, .topRight,
        ]
        variableAnchors = routeCalloutAnchors.map {
            ViewAnnotationAnchorConfig(anchor: $0)
        }
        setNeedsUpdateSize()
    }
}
