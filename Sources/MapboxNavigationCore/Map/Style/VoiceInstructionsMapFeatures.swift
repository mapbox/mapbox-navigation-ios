import _MapboxNavigationHelpers
import MapboxDirections
import MapboxMaps
import Turf

struct VoiceInstructionsTextStyleContent: MapStyleContent {
    let source: GeoJSONSource

    let symbolLayer: SymbolLayer
    let circleLayer: CircleLayer

    var body: some MapStyleContent {
        source

        symbolLayer
        circleLayer
    }
}

extension Route {
    func voiceInstructionMapFeatures(
        ids: FeatureIds.VoiceInstruction,
        customizedSymbolLayerProvider: CustomizedTypeLayerProvider<SymbolLayer>,
        customizedCircleLayerProvider: CustomizedTypeLayerProvider<CircleLayer>
    ) -> (VoiceInstructionsTextStyleContent, MapFeature)? {
        var featureCollection = FeatureCollection(features: [])

        for (legIndex, leg) in legs.enumerated() {
            for (stepIndex, step) in leg.steps.enumerated() {
                guard let instructions = step.instructionsSpokenAlongStep else { continue }
                for instruction in instructions {
                    guard let shape = legs[legIndex].steps[stepIndex].shape,
                          let coordinateFromStart = LineString(shape.coordinates.reversed())
                              .coordinateFromStart(distance: instruction.distanceAlongStep) else { continue }

                    var feature = Feature(geometry: .point(Point(coordinateFromStart)))
                    feature.properties = [
                        "instruction": .string(instruction.text),
                    ]
                    featureCollection.features.append(feature)
                }
            }
        }

        let symbolLayer = with(SymbolLayer(id: ids.layer, source: ids.source)) {
            let instruction = Exp(.toString) {
                Exp(.get) {
                    "instruction"
                }
            }

            $0.textField = .expression(instruction)
            $0.textSize = .constant(14)
            $0.textHaloWidth = .constant(1)
            $0.textHaloColor = .constant(.init(.white))
            $0.textOpacity = .constant(0.75)
            $0.textAnchor = .constant(.bottom)
            $0.textJustify = .constant(.left)
        }
        let customizedSymbolLayer = customizedSymbolLayerProvider.customizedLayer(symbolLayer)

        let circleLayer = with(CircleLayer(id: ids.circleLayer, source: ids.source)) {
            $0.circleRadius = .constant(5)
            $0.circleOpacity = .constant(0.75)
            $0.circleColor = .constant(.init(.white))
        }
        let customizedCircleLayer = customizedCircleLayerProvider.customizedLayer(circleLayer)

        let source = GeoJsonMapFeature.Source(
            id: ids.source,
            geoJson: .featureCollection(featureCollection)
        )
        guard let sourceData = source.data() else { return nil }

        let content = VoiceInstructionsTextStyleContent(
            source: sourceData,
            symbolLayer: customizedSymbolLayer,
            circleLayer: customizedCircleLayer
        )
        let mapFeature = GeoJsonMapFeature(
            id: ids.source,
            sources: [source],
            customizeSource: { _, _ in },
            layers: [symbolLayer, circleLayer]
        )
        return (content, mapFeature)
    }
}
