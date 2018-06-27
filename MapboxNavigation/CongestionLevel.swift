//
//  CongestionLevel.swift
//  MapboxNavigation
//
//  Created by Bobby Sudekum on 6/21/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import CarPlay
import MapboxDirections

extension CongestionLevel {
    /**
     Converts a CongestionLevel to a CPTimeRemainingColor.
     */
    @available(iOS 12.0, *)
    public var asCPTimeRemainingColor: CPTimeRemainingColor {
        switch self {
        case .unknown:
            return .default
        case .low:
            return .green
        case .moderate:
            return .orange
        case .heavy:
            return .red
        case .severe:
            return .red
        }
    }
}
