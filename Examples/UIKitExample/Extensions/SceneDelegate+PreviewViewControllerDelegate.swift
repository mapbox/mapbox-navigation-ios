import CoreLocation
import MapboxGeocoder
import MapboxNavigationCore
import MapboxNavigationUIKit

// MARK: - NavigationMapViewDelegate methods

extension SceneDelegate: NavigationMapViewDelegate {
    func navigationMapView(_ navigationMapView: NavigationMapView, didSelect alternativeRoute: AlternativeRoute) {
        guard let routePreviewViewController = previewViewController
            .topBanner(at: .bottomLeading) as? RoutePreviewViewController
        else {
            return
        }

        previewViewController.dismissBanner(
            at: .bottomLeading,
            animated: false
        )
        Task { [weak self] in
            guard let previewRoutes = await routePreviewViewController.routePreviewOptions.navigationRoutes
                .selecting(alternativeRoute: alternativeRoute) else { return }
            self?.preview(previewRoutes, animated: false)
        }
    }

    func navigationMapView(_ navigationMapView: NavigationMapView, userDidLongTap mapPoint: MapPoint) {
        guard let originCoordinate = navigationMapView.mapView.location.latestLocation?.coordinate else { return }

        let destinationCoordinate = mapPoint.coordinate
        let coordinates = [
            originCoordinate,
            destinationCoordinate,
        ]

        let topmostBottomBanner = previewViewController.topBanner(at: .bottomLeading)

        // In case if `RoutePreviewViewController` is shown - don't do anything.
        if topmostBottomBanner is RoutePreviewViewController {
            return
        }

        // In case if `DestinationPreviewViewController` is shown - dismiss it and after that show new one.
        if topmostBottomBanner is DestinationPreviewViewController {
            previewViewController.dismissBanner(
                at: .bottomLeading,
                animated: false
            )
            preview(
                coordinates,
                animated: false
            )
        } else {
            if shouldAnimate {
                previewViewController.navigationView.topBannerContainerView.alpha = 0.0
                previewViewController.navigationView.bottomBannerContainerView.alpha = 0.0
            }

            preview(
                coordinates,
                animated: shouldAnimate,
                duration: animationDuration,
                animations: { [self] in
                    previewViewController.navigationView.topBannerContainerView.alpha = 1.0
                    previewViewController.navigationView.bottomBannerContainerView.alpha = 1.0
                }
            )
        }
    }
}

// MARK: - PreviewViewControllerDelegate methods

extension SceneDelegate: PreviewViewControllerDelegate {
    func previewViewController(
        _ previewViewController: PreviewViewController,
        willPresent banner: Banner
    ) {
        guard let destinationPreviewViewController = banner as? DestinationPreviewViewController,
              let destinationCoordinate = destinationPreviewViewController.destinationOptions.coordinates.last
        else {
            return
        }

        // While presenting `DestinationPreviewViewController` - override its initial primary text
        // to reverse-geocoded name.
        reverseGeocode(destinationCoordinate) { placemarkName in
            destinationPreviewViewController.destinationOptions.primaryText = NSAttributedString(string: placemarkName)
        }

        previewViewController.navigationView.wayNameView.isHidden = true
        previewViewController.navigationView.speedLimitView.isAlwaysHidden = true
        previewViewController.navigationView.navigationMapView.navigationCamera.stop()
    }

    func previewViewController(
        _ previewViewController: PreviewViewController,
        didPresent banner: Banner
    ) {
        // No-op
    }

    func previewViewController(
        _ previewViewController: PreviewViewController,
        willDismiss banner: Banner
    ) {
        if banner is DestinationPreviewViewController {
            // TODO: Implement the ability to remove final destination annotations.
            previewViewController.navigationMapView.removeRoutes()
        } else if banner is RoutePreviewViewController {
            previewViewController.navigationMapView.removeRoutes()
        }
    }

    func previewViewController(
        _ previewViewController: PreviewViewController,
        didDismiss banner: Banner
    ) {
        if previewViewController.topBanner(at: .bottomLeading) == nil {
            previewViewController.navigationView.wayNameView.isHidden = false
            previewViewController.navigationView.speedLimitView.isAlwaysHidden = false
        }
    }

    // MARK: - Helper methods

    func startActiveNavigation(for navigationRoutes: NavigationRoutes) {
        previewViewController.navigationView.topBannerContainerView.hide(
            animated: shouldAnimate,
            duration: animationDuration,
            animations: { [weak self] in
                guard let self else { return }

                previewViewController.navigationView.topBannerContainerView.alpha = 0.0
            }
        )

        previewViewController.navigationView.bottomBannerContainerView.hide(
            animated: shouldAnimate,
            duration: animationDuration,
            animations: { [weak self] in
                guard let self else { return }

                previewViewController.navigationView.floatingStackView.alpha = 0.0
                previewViewController.navigationView.bottomBannerContainerView.alpha = 0.0
            },
            completion: { [weak self] _ in
                guard let self else { return }

                let navigationViewController = NavigationViewController(
                    navigationRoutes: navigationRoutes,
                    navigationOptions: NavigationOptions(
                        mapboxNavigation: navigationProvider,
                        voiceController: navigationProvider.routeVoiceController,
                        eventsManager: navigationProvider.eventsManager(),
                        styles: [NightStyle()],
                        predictiveCacheManager: navigationProvider.predictiveCacheManager
                    )
                )
                navigationViewController.modalPresentationStyle = .fullScreen
                navigationViewController.transitioningDelegate = self
                // Make `SceneDelegate` delegate of `NavigationViewController` to be notified about
                // its dismissal.
                navigationViewController.delegate = self

                previewViewController.present(
                    navigationViewController,
                    animated: true,
                    completion: { [weak self] in
                        guard let self else { return }

                        // Render part of the route that has been traversed with full transparency, to give the illusion
                        // of a disappearing route.
                        navigationViewController.routeLineTracksTraversal = true

                        // Hide top and bottom container views before animating their presentation.
                        navigationViewController.navigationView.topBannerContainerView.hide(animated: false)
                        navigationViewController.navigationView.bottomBannerContainerView.hide(animated: false)

                        if shouldAnimate {
                            navigationViewController.navigationView.speedLimitView.alpha = 0.0
                            navigationViewController.navigationView.wayNameView.alpha = 0.0
                            navigationViewController.navigationView.floatingStackView.alpha = 0.0
                            navigationViewController.navigationView.topBannerContainerView.alpha = 0.0
                            navigationViewController.navigationView.bottomBannerContainerView.alpha = 0.0
                        }

                        navigationViewController.navigationView.topBannerContainerView.show(
                            animated: shouldAnimate,
                            duration: animationDuration,
                            animations: {
                                navigationViewController.navigationView.speedLimitView.alpha = 1.0
                                navigationViewController.navigationView.wayNameView.alpha = 1.0
                                navigationViewController.navigationView.floatingStackView.alpha = 1.0
                                navigationViewController.navigationView.topBannerContainerView.alpha = 1.0
                            }
                        )

                        navigationViewController.navigationView.bottomBannerContainerView.show(
                            animated: shouldAnimate,
                            duration: animationDuration,
                            animations: {
                                navigationViewController.navigationView.bottomBannerContainerView.alpha = 1.0
                            }
                        )
                    }
                )
            }
        )
    }

    func reverseGeocode(
        _ coordinate: CLLocationCoordinate2D,
        completion: @escaping (_ placemarkName: String) -> Void
    ) {
        let reverseGeocodeOptions = ReverseGeocodeOptions(coordinate: coordinate)
        reverseGeocodeOptions.focalLocation = CLLocationManager().location
        reverseGeocodeOptions.locale = Locale.autoupdatingCurrent.languageCode == "en" ? nil : .autoupdatingCurrent
        reverseGeocodeOptions.allowedScopes = .all
        reverseGeocodeOptions.maximumResultCount = 1
        reverseGeocodeOptions.includesRoutableLocations = true

        Geocoder.shared.geocode(reverseGeocodeOptions, completionHandler: { placemarks, _, error in
            if let error {
                print("Reverse geocoding failed with error: \(error.localizedDescription)")
                return
            }

            guard let placemark = placemarks?.first else {
                print("Placemark was not found")
                return
            }

            completion(placemark.formattedName)
        })
    }
}
