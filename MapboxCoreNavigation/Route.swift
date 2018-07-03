//
//  Route.swift
//  MapboxCoreNavigation
//
//  Created by Bobby Sudekum on 7/3/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import MapboxDirections
import CarPlay

extension Route {
    /**
     Creates a `CPTravelEstimates` from a given route.
     */
    @available(iOS 12.0, *)
    public var travelEstimates: CPTravelEstimates {
        let distanceMeasurement = Measurement(value: distance, unit: UnitLength.meters)
        return CPTravelEstimates(distanceRemaining: distanceMeasurement, timeRemaining: expectedTravelTime)
    }
    
    @available(iOS 12.0, *)
    public var asCPTrip: CPTrip? {
        guard let origin = legs.first?.source else { return nil }
        guard let destination = legs.last?.destination else { return nil }
        
        let summaries = description.components(separatedBy: ", ")
        let summary = CPRouteChoice(summaryVariants: [summaries.first ?? ""],
                                 additionalInformationVariants: [summaries.last ?? ""],
                                 selectionSummaryVariants: [])
        
        return CPTrip(origin: MKMapItem(placemark: MKPlacemark(coordinate: origin.coordinate)),
                      destination: MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate, addressDictionary: [
                        "street": destination.name ?? ""
                        ])),
                      routeChoices: [summary])
    }
}
