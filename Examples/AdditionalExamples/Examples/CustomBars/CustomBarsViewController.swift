/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation
 */

import CoreLocation
import Foundation
import MapboxDirections
import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

final class CustomBarsViewController: UIViewController {
    private let mapboxNavigationProvider = MapboxNavigationProvider(
        coreConfig: .init(
            locationSource: simulationIsEnabled ? .simulation(
                initialLocation: .init(
                    latitude: 37.77440680146262,
                    longitude: -122.43539772352648
                )
            ) : .live
        )
    )
    private var mapboxNavigation: MapboxNavigation {
        mapboxNavigationProvider.mapboxNavigation
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        let options = NavigationRouteOptions(coordinates: [origin, destination])

        let request = mapboxNavigation.routingProvider().calculateRoutes(options: options)

        Task {
            switch await request.result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let navigationRoutes):
                // Pass your custom implementations of `topBanner` and/or `bottomBanner` to `NavigationOptions`
                // If you do not specify them explicitly, `TopBannerViewController` and `BottomBannerViewController`
                // will be used by default.
                // Those are `Open`, so you can also check thier source for more examples of using standard UI controls!
                let topBanner = CustomTopBarViewController()
                let bottomBanner = CustomBottomBarViewController()
                let navigationOptions = NavigationOptions(
                    mapboxNavigation: mapboxNavigation,
                    voiceController: mapboxNavigationProvider.routeVoiceController,
                    eventsManager: mapboxNavigationProvider.eventsManager(),
                    topBanner: topBanner,
                    bottomBanner: bottomBanner
                )
                let navigationViewController = NavigationViewController(
                    navigationRoutes: navigationRoutes,
                    navigationOptions: navigationOptions
                )

                bottomBanner.navigationViewController = navigationViewController

                let parentSafeArea = navigationViewController.view.safeAreaLayoutGuide
                let bannerHeight: CGFloat = 80.0
                let verticalOffset: CGFloat = 20.0
                let horizontalOffset: CGFloat = 10.0

                // To change top and bottom banner size and position change layout constraints directly.
                topBanner.view.topAnchor.constraint(equalTo: parentSafeArea.topAnchor).isActive = true

                bottomBanner.view.heightAnchor.constraint(equalToConstant: bannerHeight).isActive = true
                bottomBanner.view.bottomAnchor.constraint(
                    equalTo: parentSafeArea.bottomAnchor,
                    constant: -verticalOffset
                ).isActive = true
                bottomBanner.view.leadingAnchor.constraint(
                    equalTo: parentSafeArea.leadingAnchor,
                    constant: horizontalOffset
                ).isActive = true
                bottomBanner.view.trailingAnchor.constraint(
                    equalTo: parentSafeArea.trailingAnchor,
                    constant: -horizontalOffset
                ).isActive = true

                navigationViewController.modalPresentationStyle = .fullScreen

                present(navigationViewController, animated: true, completion: nil)
                navigationViewController.floatingButtons = []
                navigationViewController.showsSpeedLimits = false
            }
        }
    }
}

// MARK: - CustomTopBarViewController

final class CustomTopBarViewController: ContainerViewController {
    private lazy var instructionsBannerTopOffsetConstraint = instructionsBannerView.topAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.topAnchor,
        constant: 10
    )

    private lazy var centerOffset: CGFloat = calculateCenterOffset(with: view.bounds.size)
    private lazy var instructionsBannerCenterOffsetConstraint = instructionsBannerView.centerXAnchor.constraint(
        equalTo: view.centerXAnchor,
        constant: 0
    )

    private lazy var instructionsBannerWidthConstraint = instructionsBannerView.widthAnchor.constraint(
        equalTo: view.widthAnchor,
        multiplier: 0.9
    )

    // You can Include one of the existing Views to display route-specific info
    lazy var instructionsBannerView: InstructionsBannerView = {
        let banner = InstructionsBannerView()
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.heightAnchor.constraint(equalToConstant: 100.0).isActive = true
        banner.layer.cornerRadius = 25
        banner.layer.opacity = 0.75
        banner.separatorView.isHidden = true
        return banner
    }()

    override func viewDidLoad() {
        view.addSubview(instructionsBannerView)

        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateConstraints()
    }

    private func setupConstraints() {
        instructionsBannerCenterOffsetConstraint.isActive = true
        instructionsBannerTopOffsetConstraint.isActive = true
        instructionsBannerWidthConstraint.isActive = true
    }

    private func updateConstraints() {
        instructionsBannerCenterOffsetConstraint.constant = centerOffset
    }

    // MARK: - Device rotation

    private func calculateCenterOffset(with size: CGSize) -> CGFloat {
        return size.height < size.width ? -size.width / 5 : 0
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        centerOffset = calculateCenterOffset(with: size)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateConstraints()
    }

    // MARK: - NavigationComponent implementation

    func onRouteProgressUpdated(_ progress: RouteProgress) {
        // pass updated data to sub-views which also implement `NavigationComponent`
        instructionsBannerView.updateDistance(for: progress.currentLegProgress.currentStepProgress)
    }

    func onDidPassVisualInstructionPoint(_ instruction: VisualInstructionBanner) {
        instructionsBannerView.update(for: instruction)
    }
}

// MARK: - CustomBottomBarViewController

final class CustomBottomBarViewController: ContainerViewController, CustomBottomBannerViewDelegate {
    weak var navigationViewController: NavigationViewController?

    // Or you can implement your own UI elements
    lazy var bannerView: CustomBottomBannerView = {
        let banner = CustomBottomBannerView()
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.delegate = self
        return banner
    }()

    override func loadView() {
        super.loadView()

        view.addSubview(bannerView)

        let safeArea = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            bannerView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            bannerView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            bannerView.heightAnchor.constraint(equalTo: view.heightAnchor),
            bannerView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupConstraints()
    }

    private func setupConstraints() {
        if let superview = view.superview?.superview {
            view.bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor).isActive = true
        }
    }

    // MARK: - NavigationComponent implementation

    func onRouteProgressUpdated(_ progress: RouteProgress) {
        // Update your controls manually
        bannerView.progress = Float(progress.fractionTraveled)
        bannerView.eta = "~\(Int(round(progress.durationRemaining / 60))) min"
    }

    // MARK: - CustomBottomBannerViewDelegate implementation

    func customBottomBannerDidCancel(_ banner: CustomBottomBannerView) {
        navigationViewController?.dismiss(
            animated: true,
            completion: nil
        )
    }
}
