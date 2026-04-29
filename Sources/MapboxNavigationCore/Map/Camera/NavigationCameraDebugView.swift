import Combine
import MapboxMaps
import UIKit

/// `UIView`, which is drawn on top of `MapView` and shows `CameraOptions` when ``NavigationCamera`` is in
/// ``NavigationCameraState/following`` state.
///
/// Such `UIView` is useful for debugging purposes (especially when debugging camera behavior on CarPlay).
class NavigationCameraDebugView: UIView {
    weak var mapView: MapView?

    weak var viewportDataSource: ViewportDataSource? {
        didSet {
            viewportDataSourceLifetimeSubscriptions.removeAll()
            subscribe(to: viewportDataSource)
        }
    }

    private var viewportDataSourceLifetimeSubscriptions: Set<AnyCancellable> = []

    var viewportLayer = CALayer()
    var viewportTextLayer = CATextLayer()
    var anchorLayer = CALayer()
    var anchorTextLayer = CATextLayer()
    var centerLayer = CALayer()
    var centerTextLayer = CATextLayer()
    var pitchTextLayer = CATextLayer()
    var zoomTextLayer = CATextLayer()
    var bearingTextLayer = CATextLayer()
    var centerCoordinateTextLayer = CATextLayer()

    required init(
        _ mapView: MapView,
        viewportDataSource: ViewportDataSource?
    ) {
        self.mapView = mapView
        self.viewportDataSource = viewportDataSource

        super.init(frame: mapView.frame)

        isUserInteractionEnabled = false
        backgroundColor = .clear
        subscribe(to: viewportDataSource)

        viewportLayer.borderWidth = 3.0
        viewportLayer.borderColor = UIColor.green.cgColor
        layer.addSublayer(viewportLayer)

        anchorLayer.backgroundColor = UIColor.red.cgColor
        anchorLayer.frame = .init(x: 0.0, y: 0.0, width: 6.0, height: 6.0)
        anchorLayer.cornerRadius = 3.0
        layer.addSublayer(anchorLayer)

        self.anchorTextLayer = CATextLayer()
        anchorTextLayer.string = "Anchor"
        anchorTextLayer.fontSize = UIFont.systemFontSize
        anchorTextLayer.backgroundColor = UIColor.clear.cgColor
        anchorTextLayer.foregroundColor = UIColor.red.cgColor
        anchorTextLayer.frame = .zero
        layer.addSublayer(anchorTextLayer)

        centerLayer.backgroundColor = UIColor.blue.cgColor
        centerLayer.frame = .init(x: 0.0, y: 0.0, width: 6.0, height: 6.0)
        centerLayer.cornerRadius = 3.0
        layer.addSublayer(centerLayer)

        self.centerTextLayer = CATextLayer()
        centerTextLayer.string = "Center"
        centerTextLayer.fontSize = UIFont.systemFontSize
        centerTextLayer.backgroundColor = UIColor.clear.cgColor
        centerTextLayer.foregroundColor = UIColor.blue.cgColor
        centerTextLayer.frame = .zero
        layer.addSublayer(centerTextLayer)

        self.pitchTextLayer = createDefaultTextLayer()
        layer.addSublayer(pitchTextLayer)

        self.zoomTextLayer = createDefaultTextLayer()
        layer.addSublayer(zoomTextLayer)

        self.bearingTextLayer = createDefaultTextLayer()
        layer.addSublayer(bearingTextLayer)

        self.viewportTextLayer = createDefaultTextLayer()
        layer.addSublayer(viewportTextLayer)

        self.centerCoordinateTextLayer = createDefaultTextLayer()
        layer.addSublayer(centerCoordinateTextLayer)
    }

    func createDefaultTextLayer() -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.string = ""
        textLayer.fontSize = UIFont.systemFontSize
        textLayer.backgroundColor = UIColor.clear.cgColor
        textLayer.foregroundColor = UIColor.black.cgColor
        textLayer.frame = .zero

        return textLayer
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func subscribe(to viewportDataSource: ViewportDataSource?) {
        viewportDataSource?.navigationCameraOptions
            .removeDuplicates()
            .sink { [weak self] navigationCameraOptions in
                guard let self else { return }
                update(using: navigationCameraOptions)
            }.store(in: &viewportDataSourceLifetimeSubscriptions)
    }

    private func update(using navigationCameraOptions: NavigationCameraOptions) {
        guard let mapView else { return }

        let camera = navigationCameraOptions.followingCamera

        if let anchorPosition = camera.anchor {
            anchorLayer.position = anchorPosition
            anchorTextLayer.frame = .init(
                x: anchorLayer.frame.origin.x + 5.0,
                y: anchorLayer.frame.origin.y + 5.0,
                width: 80.0,
                height: 20.0
            )
        }

        if let pitch = camera.pitch {
            pitchTextLayer.frame = .init(
                x: viewportLayer.frame.origin.x + 5.0,
                y: viewportLayer.frame.origin.y + 5.0,
                width: viewportLayer.frame.size.width - 10.0,
                height: 20.0
            )
            pitchTextLayer.string = "Pitch: \(pitch)º"
        }

        if let zoom = camera.zoom {
            zoomTextLayer.frame = .init(
                x: viewportLayer.frame.origin.x + 5.0,
                y: viewportLayer.frame.origin.y + 30.0,
                width: viewportLayer.frame.size.width - 10.0,
                height: 20.0
            )
            zoomTextLayer.string = "Zoom: \(zoom)"
        }

        if let bearing = camera.bearing {
            bearingTextLayer.frame = .init(
                x: viewportLayer.frame.origin.x + 5.0,
                y: viewportLayer.frame.origin.y + 55.0,
                width: viewportLayer.frame.size.width - 10.0,
                height: 20.0
            )
            bearingTextLayer.string = "Bearing: \(bearing)º"
        }

        if let edgeInsets = camera.padding {
            viewportLayer.frame = CGRect(
                x: edgeInsets.left,
                y: edgeInsets.top,
                width: mapView.frame.width - edgeInsets.left - edgeInsets.right,
                height: mapView.frame.height - edgeInsets.top - edgeInsets.bottom
            )

            viewportTextLayer.frame = .init(
                x: viewportLayer.frame.origin.x + 5.0,
                y: viewportLayer.frame.origin.y + 80.0,
                width: viewportLayer.frame.size.width - 10.0,
                height: 20.0
            )
            viewportTextLayer
                .string =
                "Padding: (top: \(edgeInsets.top), left: \(edgeInsets.left), bottom: \(edgeInsets.bottom), right: \(edgeInsets.right))"
        }

        if let centerCoordinate = camera.center {
            centerLayer.position = mapView.mapboxMap.point(for: centerCoordinate)
            centerTextLayer.frame = .init(
                x: centerLayer.frame.origin.x + 5.0,
                y: centerLayer.frame.origin.y + 5.0,
                width: 80.0,
                height: 20.0
            )

            centerCoordinateTextLayer.frame = .init(
                x: viewportLayer.frame.origin.x + 5.0,
                y: viewportLayer.frame.origin.y + 105.0,
                width: viewportLayer.frame.size.width - 10.0,
                height: 20.0
            )
            centerCoordinateTextLayer
                .string = "Center coordinate: (lat: \(centerCoordinate.latitude), lng:\(centerCoordinate.longitude))"
        }
    }
}
