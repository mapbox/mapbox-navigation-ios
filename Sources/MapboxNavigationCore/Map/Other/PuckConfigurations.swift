import _MapboxNavigationHelpers
@_spi(Experimental) import MapboxMaps
import UIKit

extension Puck3DConfiguration {
    private static let modelURL = Bundle.mapboxNavigationUXCore.url(forResource: "3DPuck", withExtension: "glb")!

    /// Default 3D user puck configuration
    public static let navigationDefault = Puck3DConfiguration(
        model: Model(uri: modelURL),
        modelScale: .constant([1.5, 1.5, 1.5]),
        modelOpacity: .constant(1),
        // Turn off shadows as it greatly affect performance due to constant shadow recalculation.
        modelCastShadows: .constant(false),
        modelReceiveShadows: .constant(false),
        modelEmissiveStrength: .constant(0)
    )
}

extension Puck2DConfiguration {
    public static let navigationDefault = Puck2DConfiguration(
        topImage: UIColor.clear.image(CGSize(width: 1.0, height: 1.0)),
        bearingImage: .init(named: "puck", in: .mapboxNavigationUXCore, compatibleWith: nil),
        showsAccuracyRing: false,
        opacity: 1
    )

    static let emptyPuck: Self = {
        // Since Mapbox Maps will not provide location data in case if `LocationOptions.puckType` is
        // set to nil, we have to draw empty and transparent `UIImage` instead of puck. This is used
        // in case when user wants to stop showing location puck or draw a custom one.
        let clearImage = UIColor.clear.image(CGSize(width: 1.0, height: 1.0))
        return Puck2DConfiguration(
            topImage: clearImage,
            bearingImage: clearImage,
            shadowImage: clearImage,
            scale: nil,
            showsAccuracyRing: false
        )
    }()
}
