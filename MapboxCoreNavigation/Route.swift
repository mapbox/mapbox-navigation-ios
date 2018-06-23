//
//  Route.swift
//  MapboxCoreNavigation
//
//  Created by Bobby Sudekum on 6/22/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import MapboxDirections
import CarPlay


extension Array where Element: Route {
    /**
     Creates a CPTrip from an array of routes.
     */
    public func tripFor(for addressDictionary: [String : Any]) -> CPTrip? {
        guard let origin = first?.legs.first?.source.coordinate else { return nil }
        guard let destination = last?.legs.last?.destination.coordinate else { return nil }
        
        let routeChoices: [CPRouteChoice] = map {
            let summary = $0.description.components(separatedBy: ", ")
            return CPRouteChoice(summaryVariants: [summary.first ?? ""],
                                 additionalInformationVariants: [summary.last ?? summary.first ?? ""],
                                 selectionSummaryVariants: [])
        }
        
        return CPTrip(origin: MKMapItem(placemark: MKPlacemark(coordinate: origin)),
                      destination: MKMapItem(placemark: MKPlacemark(coordinate: destination, addressDictionary: addressDictionary)),
                      routeChoices: routeChoices)
    }
}
