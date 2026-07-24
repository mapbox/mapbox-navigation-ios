import _MapboxNavigationHelpers
@_spi(Experimental) import MapboxMaps
import MapboxNavigationCore
import UIKit

extension Puck3DConfiguration {
    private static let carPlayModelURL =
        Bundle.mapboxNavigationUXCore.url(forResource: "3DPuck", withExtension: "glb")!

    /// 3D puck configuration for SDK-managed CarPlay maps on compact displays.
    static let carPlayCompact: Self = {
        var configuration = carPlayHD
        configuration.modelScale = .constant([1.0, 1.0, 1.0])
        return configuration
    }()

    /// 3D puck configuration for SDK-managed CarPlay maps on higher-resolution displays.
    static let carPlayHD = Puck3DConfiguration(
        model: Model(uri: carPlayModelURL),
        modelScale: .constant([1.1, 1.1, 1.1]),
        modelOpacity: .constant(1),
        // Turn off shadows as they significantly affect performance due to constant shadow recalculation.
        modelCastShadows: .constant(false),
        modelReceiveShadows: .constant(false),
        modelEmissiveStrength: .constant(0)
    )
}

extension Puck2DConfiguration {
    /// 2D puck configuration for SDK-managed CarPlay maps on compact displays.
    static let carPlayCompact: Self = {
        var configuration = carPlayHD
        configuration.scale = .constant(0.6)
        return configuration
    }()

    /// 2D puck configuration for SDK-managed CarPlay maps on higher-resolution displays.
    static let carPlayHD = Puck2DConfiguration(
        topImage: UIColor.clear.image(CGSize(width: 1.0, height: 1.0)),
        bearingImage: .init(named: "puck", in: .mapboxNavigationUXCore, compatibleWith: nil),
        scale: .constant(0.8),
        showsAccuracyRing: false,
        opacity: 1
    )
}
