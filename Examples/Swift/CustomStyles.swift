//
//  CustomStyles.swift
//  Example-Swift
//
//  Created by Bobby Sudekum on 7/11/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import MapboxNavigation

/**
 To find more pieces of the UI to customize, checkout DayStyle.swift.
 */
// MARK: CustomDayStyle
class CustomDayStyle: DayStyle {
    
    required init() {
        super.init()
        mapStyleURL = URL(string: "mapbox://styles/mapbox/satellite-streets-v9")!
        styleType = .day
    }
    
    override func apply() {
        super.apply()
        BottomBannerView.appearance().backgroundColor = .orange
    }
}

// MARK: CustomNightStyle
class CustomNightStyle: NightStyle {
    
    required init() {
        super.init()
        mapStyleURL = URL(string: "mapbox://styles/mapbox/satellite-streets-v9")!
        styleType = .night
    }
    
    override func apply() {
        super.apply()
        BottomBannerView.appearance().backgroundColor = .purple
    }
}
