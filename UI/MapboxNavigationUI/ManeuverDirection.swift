//
//  ManeuverDirection.swift
//
//  Created by Qian Gao on 10/18/16.
//  Copyright © 2016 Mapbox. All rights reserved.
//

import Foundation
import MapboxDirections



extension ManeuverDirection {
    init(angle: Int) {
        var description: String
        switch angle {
        case -30..<30:
            description = "straight"
        case 30..<60:
            description = "slight right"
        case 60..<150:
            description = "right"
        case 150..<180:
            description = "sharp right"
        case -180..<(-150):
            description = "sharp left"
        case -150..<(-60):
            description = "left"
        case -50..<(-30):
            description = "slight left"
        default:
            description = "straight"
        }
        self.init(description: description)!
    }
}
