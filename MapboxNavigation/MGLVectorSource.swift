//
//  MGLVectorSource.swift
//  MapboxNavigation
//
//  Created by Bobby Sudekum on 4/18/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//

import Foundation
import Mapbox

extension MGLVectorSource {
    var isMapboxStreets: Bool {
        guard let configurationURL = configurationURL else {
            return false
        }
        return configurationURL.scheme == "mapbox" && configurationURL.host!.components(separatedBy: ",").contains("mapbox.mapbox-streets-v7")
    }
}
