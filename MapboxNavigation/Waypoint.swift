//
//  Waypoint.swift
//  MapboxNavigation
//
//  Created by Jerrad Thramer on 12/5/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//

import Foundation
import MapboxDirections

extension Waypoint {
    var location: CLLocation {
        return CLLocation.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
