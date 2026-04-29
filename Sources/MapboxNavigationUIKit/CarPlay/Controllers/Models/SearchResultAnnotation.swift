//
//  SearchResultAnnotation.swift
//
//
//  Created by Maksim Chizhavko on 1/16/25.
//

import CoreLocation
import Foundation
import MapboxMaps

struct SearchResultAnnotation: PointAnnotatable {
    var searchResultRecord: SearchResultRecord

    var coordinate: CLLocationCoordinate2D {
        searchResultRecord.coordinate
    }
}
