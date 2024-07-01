import Foundation
import MapboxMaps
import MapboxNavigationUIKit
import UIKit

// MARK: CustomDayStyle

/**
 To find more pieces of the UI to customize, check out DayStyle.swift.
 */
class CustomDayStyle: StandardDayStyle {
    required init() {
        super.init()

        mapStyleURL = URL(string: StyleURI.satelliteStreets.rawValue)!
        previewMapStyleURL = mapStyleURL
        styleType = .day
    }

    override func apply() {
        super.apply()

        let traitCollection = UIScreen.main.traitCollection
        BottomBannerView.appearance(for: traitCollection).backgroundColor = .orange
        BottomPaddingView.appearance(for: traitCollection).backgroundColor = .orange
    }
}

// MARK: CustomNightStyle

class CustomNightStyle: StandardNightStyle {
    required init() {
        super.init()

        mapStyleURL = URL(string: StyleURI.satelliteStreets.rawValue)!
        previewMapStyleURL = mapStyleURL
        styleType = .night
    }

    override func apply() {
        super.apply()

        let traitCollection = UIScreen.main.traitCollection
        BottomBannerView.appearance(for: traitCollection).backgroundColor = .purple
        BottomPaddingView.appearance(for: traitCollection).backgroundColor = .purple
    }
}
