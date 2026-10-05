import Foundation
@_spi(Marshalling) @_spi(Internal) import MapboxCoreMaps
internal import MapboxCoreMaps_Private
internal import MapboxNavSdkRoadCameras
import UIKit

/// The visual style for a road camera icon.
@_spi(ExperimentalMapboxAPI)
public struct RoadCameraStyle: Sendable {
    /// The camera image.
    public let image: UIImage

    /// The image center offset.
    public let imageOffset: CGPoint

    public init(image: UIImage, imageOffset: CGPoint) {
        self.image = image
        self.imageOffset = imageOffset
    }
}

extension RoadCameraStyle {
    var native: MapboxNavSdkRoadCameras.RoadCameraStyle? {
        nativeImage.flatMap { MapboxNavSdkRoadCameras.RoadCameraStyle(image: $0, imageOffset: nativeImageOffset) }
    }

    var nativeImage: __MBXImage? {
        MBXImage(uiImage: image).flatMap { MBXImage.Marshaller.toObjc($0) }
    }

    var nativeImageOffset: __ScreenCoordinate {
        __ScreenCoordinate(x: imageOffset.x, y: imageOffset.y)
    }
}

/// Provider interface for road camera icons customization.
@_spi(ExperimentalMapboxAPI)
public protocol RoadCamerasIconProvider {
    func provideIcon(for roadCamera: RoadCamera) -> RoadCameraStyle?
}

/// Adapts a ``RoadCamerasIconProvider`` implementation to the native.
final class RoadCamerasIconProviderAdapter: NSObject, MapboxNavSdkRoadCameras.RoadCamerasIconProvider {
    private let provider: RoadCamerasIconProvider

    init(_ provider: RoadCamerasIconProvider) {
        self.provider = provider
    }

    func provideIcon(for roadCamera: MapboxNavSdkRoadCameras.RoadCamera) -> MapboxNavSdkRoadCameras.RoadCameraStyle? {
        let platformCamera = RoadCamera(roadCamera)
        guard let style = provider.provideIcon(for: platformCamera) else { return nil }
        return style.native
    }
}
