//
//  BuildingExtrusionStyler.swift
//  Apex
//
//  Created by Avi Cieplinski on 4/9/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation
import UIKit

struct ExtrudedBuilding {
    let identifier: Int
    let color: UIColor
}

class BuildingExtrusionStyler {
    private unowned let mapView: MGLMapView
    private var extrudedBuildingFeatureIDs = [Int: UIColor]() // paired list of features and colors. Includes building parts
    private let tilequeryRequestGroup = DispatchGroup()
    private let extrudedBuildingFeatureIDDispatchQueue = DispatchQueue(label: "com.mapbox.Apex.extrudedBuildings", attributes: .concurrent)
    private let regularBuildingPredicate = "extrude = 'true' && type = 'building' && underground = 'false'"
    private let apexBuildingStyleLayerIdentifier = "highlighted-building-extrusion-layer-id"

    private var coordinateColorList: [(CLLocationCoordinate2D, UIColor)]?
    
    private var extrudedBuildingsFillColor: UIColor = UIColor.green

    init(mapView: MGLMapView) {
        self.mapView = mapView
    }
    
    deinit {
        remove()
    }

    private var targetLayer: MGLStyleLayer? {
        guard let style = mapView.style else { return nil }

        var layer: MGLStyleLayer?

        // see if the style contains a destination annotation
        let pointAnnotation = style.layers.filter { layer -> Bool in
            return layer.identifier.contains("com.mapbox.annotations.points")
        }

        if pointAnnotation.count > 0 {
            layer = pointAnnotation.first
        } else {
            let scalerankLayers = style.layers.filter { layer -> Bool in
                return layer.identifier.contains("poi-scalerank")
            }

            layer = scalerankLayers.first
        }
        
        return layer
    }

    private func addStyleLayersIfNecessary() {
        if let style = mapView.style, let buildingsPlusSource = style.source(withIdentifier: "composite") {

            let highlightedBuildingsLayer = mapView.style?.layer(withIdentifier: apexBuildingStyleLayerIdentifier) as? MGLFillExtrusionStyleLayer
            guard highlightedBuildingsLayer == nil else { return }

            let highlightedBuildingLayer = MGLFillExtrusionStyleLayer(identifier: apexBuildingStyleLayerIdentifier, source: buildingsPlusSource)
            highlightedBuildingLayer.sourceLayerIdentifier = "buildings_plus"
            highlightedBuildingLayer.fillExtrusionColor = NSExpression(forConstantValue: UIColor.white)
            highlightedBuildingLayer.fillExtrusionHeightTransition = MGLTransition(duration: 0.8, delay: 0)
            highlightedBuildingLayer.fillExtrusionOpacityTransition = MGLTransition(duration: 0.8, delay: 0)

            if let targetLayer = targetLayer {
                style.insertLayer(highlightedBuildingLayer, below: targetLayer)
            } else {
                style.addLayer(highlightedBuildingLayer)
            }

            // hide layers with identifiers starting with 'building-extrusion' & 'buildings-plus'
            let buildingLayers = mapView.style?.layers.filter({ styleLayer -> Bool in
                guard let layer = styleLayer as? MGLFillExtrusionStyleLayer, layer.identifier != apexBuildingStyleLayerIdentifier, layer.sourceIdentifier == "composite", let sourceLayerIdentifier = layer.sourceLayerIdentifier, sourceLayerIdentifier.contains("building") else { return false }
                return true
            })

            buildingLayers?.forEach({ styleLayer in
                styleLayer.isVisible = false
            })
        }
    }

    private func setOpacity(opacity: Float) {
        guard let highlightedBuildingFillExtrusionLayer = mapView.style?.layer(withIdentifier: apexBuildingStyleLayerIdentifier) as? MGLFillExtrusionStyleLayer else { return }
        let opacityStops = [15: 0.5, 17: opacity]
        highlightedBuildingFillExtrusionLayer.fillExtrusionOpacity = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", opacityStops)
    }

    public func showAllBuildings(color: UIColor, opacity: Float) {
        extrudedBuildingFeatureIDs.removeAll()
        addStyleLayersIfNecessary()
        setOpacity(opacity: opacity)

        if let buildingFillExtrusionLayer = mapView.style?.layer(withIdentifier: apexBuildingStyleLayerIdentifier) as? MGLFillExtrusionStyleLayer {
            buildingFillExtrusionLayer.predicate = NSPredicate(format: regularBuildingPredicate)
            buildingFillExtrusionLayer.fillExtrusionColor = NSExpression(forConstantValue: color)
            let heightDictionary = [0: NSExpression(forConstantValue: 0), 15: NSExpression(forConstantValue: 0), 15.25: NSExpression(forKeyPath: "height")]
            let baseHeightDictionary = [0: NSExpression(forConstantValue: 0), 15: NSExpression(forConstantValue: 0), 15.25: NSExpression(forKeyPath: "min_height")]

            buildingFillExtrusionLayer.fillExtrusionHeight = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", heightDictionary)
            buildingFillExtrusionLayer.fillExtrusionBase = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", baseHeightDictionary)

        }
    }

    public func extrudeBuildings(at coordinates: [CLLocationCoordinate2D], radii: [Float], highlightColor: UIColor, extrudeAll: Bool) {
        guard coordinates.count == radii.count else { return }
        
        let buildings = coordinates.enumerated().map { (coordinate: $1, highlightColor: highlightColor, radius: radii[$0]) }
        extrudeBuildings(for: buildings, extrudeAll: extrudeAll)
    }

    public func extrudeBuildings(for coordinates: [(CLLocationCoordinate2D, UIColor)], extrudeAll: Bool) {
        let buildings = coordinates.map {return (coordinate: $0.0, highlightColor: $0.1, radius: Float(1.0))}
        extrudeBuildings(for: buildings, extrudeAll: extrudeAll)
    }
    
    public func extrudeBuildings(for buildings: [(coordinate: CLLocationCoordinate2D, highlightColor: UIColor, radius: Float)], extrudeAll: Bool) {
        extrudedBuildingFeatureIDs.removeAll()
        coordinateColorList = buildings.map {return ($0.coordinate, $0.highlightColor)}

        extrudeBuildingsWithVisibleFeatures(for: buildings, extrudeAll: extrudeAll)
//        extrudeBuildingsWithTilequery(for: buildings, extrudeAll: extrudeAll)
    }
    
    private func processFeatures(features: [[String: Any?]]) {
        for featureDict in features {
            var color = extrudedBuildingsFillColor
            if let featureGeometry = featureDict["geometry"] as? [String: Any?],
                let coordinateDict = featureGeometry["coordinates"] as? [Double] {
                let longitude = coordinateDict[0]
                let latitude = coordinateDict[1]
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let colorEntry = coordinateColorList?.first(where: { (colorEntry) -> Bool in
                    return colorEntry.0 == coordinate
                })
                if let colorValue = colorEntry?.1, let id = featureDict["id"] as? Int {
                    color = colorValue
                    self.extrudedBuildingFeatureIDs[id] = color
                }
            }

            // look for and append any parts of this building that are specified so we get the entire visual structure of some buildings such as the Ferry Building in SF. Make sure each part will be colored with the matching color
            if let properties = featureDict["properties"] as? [String: Any?], let parts = properties["parts"] as? String, let firstCharacter = parts.first, let lastCharacter = parts.last, firstCharacter == "[", lastCharacter == "]" {
                let substring = parts.dropLast().dropFirst()
                let partFeatureIDStrings = substring.split(separator: ",")
                let featureIDIntArray = partFeatureIDStrings.map { Int($0)!}
                featureIDIntArray.forEach { featureID in
                    self.extrudedBuildingFeatureIDs[featureID] = color
                }
            }
        }
    }
    
// MARK: Visible Features
    private func extrudeBuildingsWithVisibleFeatures(for buildings: [(coordinate: CLLocationCoordinate2D, highlightColor: UIColor, radius: Float)], extrudeAll: Bool) {
        var buildingsToExtrude = [ExtrudedBuilding]()
        
        buildings.forEach { buildingInfo in
            if let buildingId = getBuildingId(coordinate: buildingInfo.coordinate) {
                buildingsToExtrude.append(ExtrudedBuilding(identifier: buildingId, color: buildingInfo.highlightColor))
            }
        }
        
        extrudeBuildings(buildingsToExtrude, extrudeAll: extrudeAll)
    }
    
    private func getBuildingId(coordinate: CLLocationCoordinate2D?) -> Int? {
        guard let coord = coordinate else { return nil }
    
        let screenCoordinateForGeoCoordinate = mapView.convert(coord, toPointTo: mapView)
        let visibleFeatures = mapView.visibleFeatures(at: screenCoordinateForGeoCoordinate, styleLayerIdentifiers: [apexBuildingStyleLayerIdentifier], predicate: NSPredicate(format: regularBuildingPredicate) )
        
        if let feature = visibleFeatures.first, let buildingId = feature.identifier as? Int {
            return buildingId
        }
        
        return nil
    }

    public func remove() {
        extrudedBuildingFeatureIDs.removeAll()
        if let style = mapView.style, let highlightedBuildingsLayer = mapView.style?.layer(withIdentifier: apexBuildingStyleLayerIdentifier) as? MGLFillExtrusionStyleLayer {
            style.removeLayer(highlightedBuildingsLayer)
        }

        // hide layers with identifiers: 'building-extrusion' & 'buildings-plus'
        let buildingLayers = mapView.style?.layers.filter({ styleLayer -> Bool in
            guard let layer = styleLayer as? MGLFillExtrusionStyleLayer, layer.sourceIdentifier == "composite", let sourceLayerIdentifier = layer.sourceLayerIdentifier, sourceLayerIdentifier.contains("building") else { return false }
            return true
        })

        buildingLayers?.forEach({ styleLayer in
            styleLayer.isVisible = false
        })
    }

    public func removeHighlights(extrudeAll: Bool) {
        extrudedBuildingFeatureIDs.removeAll()
        showAllBuildings(color: extrudedBuildingsFillColor, opacity: 0.9)
    }

    private func extrudeBuildings(_ buildings: [ExtrudedBuilding], extrudeAll: Bool) {
        guard buildings.count > 0 else {
            return
        }

        addStyleLayersIfNecessary() // may need to re-add the layers if the map style has changed (e.g. preview style -> nav style)

        let opacity = 0.8
        setOpacity(opacity: Float(opacity))

        if let highlightedBuildingFillExtrusionLayer = mapView.style?.layer(withIdentifier: apexBuildingStyleLayerIdentifier) as? MGLFillExtrusionStyleLayer {
            if extrudeAll == false {
                // form a predicate to filter out the other buildings from the datasource so only the desired ones are included
                var identifiersBoolean = "($featureIdentifier == \(buildings.first!.identifier)"

                if buildings.count > 1 {
                    for building in buildings[1...buildings.count-1] {
                        identifiersBoolean += " || $featureIdentifier == \(building.identifier)"
                    }
                }

                identifiersBoolean += ")"

                let predicateString = regularBuildingPredicate + " && \(identifiersBoolean)"
                highlightedBuildingFillExtrusionLayer.predicate = NSPredicate(format: predicateString)
            } else {
                // use just the general predicate so all buildings are included in the extrusion
                highlightedBuildingFillExtrusionLayer.predicate = NSPredicate(format: regularBuildingPredicate)
            }

            // we have some specific building IDs that we will be the highlight color
            // the rest of the buildings will be extruded but kept at a uniform color
            var colorsList = [UIColor]()
            var highlightedBuildingHeightExpression = "MGL_MATCH($featureIdentifier, "
            var highlightedBuildingColorExpression = "MGL_MATCH($featureIdentifier, "

            for building in buildings {
                highlightedBuildingHeightExpression += "\(building.identifier), height, "
                highlightedBuildingColorExpression += "\(building.identifier), %@, "
                colorsList.append(building.color)
            }

            highlightedBuildingColorExpression += "%@)"
            colorsList.append(extrudedBuildingsFillColor)

            if extrudeAll == true {
                highlightedBuildingHeightExpression += "height)"
            } else {
                highlightedBuildingHeightExpression += "0)"
            }

            let heightDictionary = [0: NSExpression(forConstantValue: 0), 15: NSExpression(forConstantValue: 0), 15.25: NSExpression(format: highlightedBuildingHeightExpression)]
            let baseHeightDictionary = [0: NSExpression(forConstantValue: 0), 15: NSExpression(forConstantValue: 0), 15.25: NSExpression(forKeyPath: "min_height")]
            highlightedBuildingFillExtrusionLayer.fillExtrusionHeight = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", heightDictionary)
            highlightedBuildingFillExtrusionLayer.fillExtrusionBase = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", baseHeightDictionary)

            highlightedBuildingFillExtrusionLayer.fillExtrusionColor = NSExpression(format: highlightedBuildingColorExpression, argumentArray: colorsList)
        }
    }
}

public extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return self.filter { seen.insert($0).inserted }
    }
}
