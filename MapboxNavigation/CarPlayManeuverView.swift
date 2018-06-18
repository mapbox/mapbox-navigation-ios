//
//  CarPlayManeuverView.swift
//  MapboxNavigation
//
//  Created by Bobby Sudekum on 6/18/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import CarPlay
import MapboxCoreNavigation

public class CarPlayManeuverView: CPManeuver {
    
    
    init(routProgress: RouteProgress) {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
