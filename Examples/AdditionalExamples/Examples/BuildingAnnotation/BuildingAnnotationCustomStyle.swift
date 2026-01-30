/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation
 */

import Foundation
import MapboxMaps
import MapboxNavigationUIKit

/// Custom navigation style for the BuildingAnnotation example.
///
/// Uses a Standard-based custom style that supports building queries and 3D buildings.
class BuildingAnnotationCustomStyle: StandardDayStyle {
    required init() {
        super.init()

        // Map style needs to expose the `height` property on building features
        let customStyleURL = URL(string: "mapbox://styles/mapbox/standard")!

        mapStyleURL = customStyleURL
        previewMapStyleURL = customStyleURL
    }

    override func apply() {
        super.apply()
        // Additional UI customization can be added here if needed
    }
}
