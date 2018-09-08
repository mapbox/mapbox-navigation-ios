# Changes to the Mapbox Navigation SDK for iOS

## v0.20.0 (September 6, 2018)

### User interface

* While traveling on a numbered road, the route number is displayed in a shield beside the current road name at the bottom of the map. ([#1576](https://github.com/mapbox/mapbox-navigation-ios/pull/1576)) 
* Added the `shouldManageApplicationIdleTimer` flag to `NavigationViewController` to allow applications to opt out of automatic `UIApplication.isIdleTimerDisabled` management. ([#1591](https://github.com/mapbox/mapbox-navigation-ios/pull/1591))
* Added various methods, properties, and initializers to `StatusView`, allowing you to use it in a custom user interface. ([#1612](https://github.com/mapbox/mapbox-navigation-ios/pull/1612))
* Added `StyleManager.automaticallyAdjustsStyleForTimeOfDay`, `StyleManager.delegate`, and `StyleManager.styles` properties so that you can control same time-based style switching just as `NavigationViewController` does. [#1617](https://github.com/mapbox/mapbox-navigation-ios/pull/1617)
* Fixed an issue where the banner was stuck on rerouting past the reroute threshold when simulating navigation. ([#1583](https://github.com/mapbox/mapbox-navigation-ios/pull/1583))
* Fixed an issue where the banner appears in the wrong colors after you tap the Resume button. ([#1588](https://github.com/mapbox/mapbox-navigation-ios/pull/1588), [#1589](https://github.com/mapbox/mapbox-navigation-ios/pull/1589))
* `NavigationMapView`’s user puck now responds to changes to the safe area insets while tracking the user’s location, matching the behavior of the map camera. ([#1653](https://github.com/mapbox/mapbox-navigation-ios/pull/1653))
* Added `StepsViewControllerDelegate` and `InstructionsBannerViewDelegate` which makes it possible to listen in on tap events that occur in `StepsViewController` and `InstructionsBannerView`. [#1633](https://github.com/mapbox/mapbox-navigation-ios/pull/1633)

### Feedback

* Added a `FeedbackViewController` class for soliciting feedback from the user in a custom user interface. ([#1605](https://github.com/mapbox/mapbox-navigation-ios/pull/1605))
* Replaced `NavigationViewControllerDelegate.navigationViewControllerDidOpenFeedback(_:)` with `FeedbackViewControllerDelegate.feedbackViewControllerDidOpen(_:)`, `NavigationViewControllerDelegate.navigationViewControllerDidCancelFeedback(_:)` with `FeedbackViewControllerDelegate.feedbackViewController(_:didSend:uuid:)`, and `NavigationViewControllerDelegate.navigationViewController(_:didSendFeedbackAssigned:feedbackType)` with `FeedbackViewControllerDelegate.feedbackViewControllerDidCancel(_:)`. ([#1605](https://github.com/mapbox/mapbox-navigation-ios/pull/1605))
* Fixed a crash that occurred when the end of route view controller appears, showing the keyboard. ([#1599](https://github.com/mapbox/mapbox-navigation-ios/pull/1599/))

### Other changes

* Added a `MapboxVoiceController.audioPlayer` property. You can use this property to interrupt a spoken instruction or adjust the volume. ([#1596](https://github.com/mapbox/mapbox-navigation-ios/pull/1596))
* Fixed a memory leak when `RouteController.isDeadReckoningEnabled` is enabled. ([#1624](https://github.com/mapbox/mapbox-navigation-ios/pull/1624))

## v0.19.2 (August 23, 2018)

* The `MGLStyle.navigationGuidanceDayStyleURL` and `MGLStyle.navigationGuidanceNightStyleURL` properties now return [version 4 of the Mapbox Navigation Guidance Day and Night styles](https://blog.mapbox.com/incidents-are-live-on-the-map-beeff6b84bf9), respectively. These styles indicate incidents such as road closures and detours. ([#1619](https://github.com/mapbox/mapbox-navigation-ios/pull/1619])
* Added an `MGLMapView.showsIncidents` property to toggle the visibility of any Mapbox Incidents data on a map view. ([#1613](https://github.com/mapbox/mapbox-navigation-ios/pull/1613))

## v0.19.1 (August 15, 2018)

* Fixed build errors when installing this SDK with Mapbox Maps SDK for iOS v4.3.0 or above. ([#1608](https://github.com/mapbox/mapbox-navigation-ios/pull/1608), [#1609](https://github.com/mapbox/mapbox-navigation-ios/pull/1609))

## v0.19.0 (July 24, 2018)

### Packaging

* Moved guides and examples to [a new Mapbox Navigation SDK for iOS website](https://www.mapbox.com/ios-sdk/navigation/). ([#1552](https://github.com/mapbox/mapbox-navigation-ios/pull/1552))
* Applications intended for use in mainland China can set the `MGLMapboxAPIBaseURL` key in Info.plist to `https://api.mapbox.cn/` to use China-optimized APIs. This setting causes `NavigationMapView` to default to China-optimized day and night styles with places and roads labeled in Simplified Chinese. ([#1558](https://github.com/mapbox/mapbox-navigation-ios/pull/1558))

### User interface

* Fixed an issue where selecting a step from the steps list would take the user to the wrong step. ([#1524](https://github.com/mapbox/mapbox-navigation-ios/pull/1524/))
* The `StyleManagerDelegate.locationFor(styleManager:)` method’s return value is now optional. ([#1523](https://github.com/mapbox/mapbox-navigation-ios/pull/1523))
* `NavigationViewController` smoothly fades between light and dark status bars. ([#1535](https://github.com/mapbox/mapbox-navigation-ios/pull/1535))
* Renamed the `InstructionsBannerView.updateInstruction(_:)` method to `InstructionsBannerView.update(for:)`. Added the `NextBannerView.update(for:)` and `LanesView.update(for:)` methods. These methods are intended to be called in response to `Notification.Name.routeControllerDidPassVisualInstructionPoint` if the views are used outside a `NavigationViewController`. By contrast, `InstructionsBannerView.updateDistance(for:)` should be called on every location update. ([#1514](https://github.com/mapbox/mapbox-navigation-ios/pull/1514))
* Added the `ManeuverView.visualInstruction` and `ManeuverView.drivingSide` properties. ([#1514](https://github.com/mapbox/mapbox-navigation-ios/pull/1514))

## v0.18.1 (June 19, 2018)

### Packaging

* Increased the minimum deployment target of Core Navigation to iOS 9. ([#1494](https://github.com/mapbox/mapbox-navigation-ios/pull/1494))

### User interface

* Added `NavigationMapView.recenterMap()` for recentering the map if a user gesture causes it to stop following the user. ([#1471](https://github.com/mapbox/mapbox-navigation-ios/pull/1471))
* Deprecated `NavigationViewController.usesNightStyleInsideTunnels`. Style switching is enabled as a side effect of `TunnelIntersectionManager.tunnelSimulationEnabled`, which is set to `true` by default. ([#1489]
* Fixed an issue where the user location view slid around after the user pressed the Overview button. [#1506](https://github.com/mapbox/mapbox-navigation-ios/pull/1506)

### Core Navigation

* Moved `RouteController.tunnelSimulationEnabled` to `TunnelIntersectionManager.tunnelSimulationEnabled`. ([#1489](https://github.com/mapbox/mapbox-navigation-ios/pull/1489))
(https://github.com/mapbox/mapbox-navigation-ios/pull/1489))
* Added `RouteControllerDelegate.routeControllerWillDisableBatteryMonitoring(_:)` which allows developers control whether battery monitoring is disabled when `RouteController.deinit()` is called. [#1476](https://github.com/mapbox/mapbox-navigation-ios/pull/1476)
* Fixed an issue where setting `NavigationLocationManager.desiredAccuracy` had no effect. [#1481](https://github.com/mapbox/mapbox-navigation-ios/pull/1481)

## v0.18.0 (June 5, 2018)

### User interface

* Added support for generic route shields. Image-backed route shields also now display as generic (instead of plain text) while the SDK loads the image. [#1190](https://github.com/mapbox/mapbox-navigation-ios/issues/1190), [#1417](https://github.com/mapbox/mapbox-navigation-ios/pull/1417)
* Fixed an issue when going into overhead mode with a short route. [#1456](https://github.com/mapbox/mapbox-navigation-ios/pull/1456/)
* Adds support for Xcode 10 Beta 1. [#1499](https://github.com/mapbox/mapbox-navigation-ios/pull/1499), [#1478](https://github.com/mapbox/mapbox-navigation-ios/pull/1478)

### Core Navigation

* `TunnelIntersectionManagerDelegate` methods no longer take a completion handler argument. ([#1414](https://github.com/mapbox/mapbox-navigation-ios/pull/1414))
* Added the ability to render more than 1 alternate route. [#1372](https://github.com/mapbox/mapbox-navigation-ios/pull/1372/)
* `NavigationMapViewDelegate.navigationMapView(_:shapeFor:)` Now expects an array of `Route`. The first route will be rendered as the main route, all subsequent routes will be rendered as alternate routes.
* Animating the user through tunnels and automatically switching the map style when entering a tunnel is now on by default. [#1449](https://github.com/mapbox/mapbox-navigation-ios/pull/1449)
* Adds `RouteControllerDelegate.routeController(_:shouldPreventReroutesWhenArrivingAt:waypoint:)` which is called each time a driver arrives at a waypoint. By default, this method returns true and prevents rerouting upon arriving. Progress updates still occur. [#1454](https://github.com/mapbox/mapbox-navigation-ios/pull/1454/)

## v0.17.0 (May 14, 2018)

### Packaging

* Upgraded to the [Mapbox Maps SDK for iOS v4.0.0](https://github.com/mapbox/mapbox-gl-native/releases/tag/ios-v4.0.0). If you have customized the route map’s appearance, you may need to migrate your code to use expressions instead of style functions. ([#1076](https://github.com/mapbox/mapbox-navigation-ios/pull/1076))
* Added a Korean localization. ([#1346](https://github.com/mapbox/mapbox-navigation-ios/pull/1346))

### User interface

* Exit indications are now drawn accurately with a correct exit heading. ([#1288](https://github.com/mapbox/mapbox-navigation-ios/pull/1288))
* Added the `NavigationViewControllerDelegate.navigationViewController(_:roadNameAt:)` method for customizing the contents of the road name label that appears towards the bottom of the map view. ([#1309](https://github.com/mapbox/mapbox-navigation-ios/pull/1309))
* If the SDK tries but fails to reroute the user, the “Rerouting…” status view no longer stays visible permanently. ([#1357](https://github.com/mapbox/mapbox-navigation-ios/pull/1357))
* Completed waypoints now remain on the map but are slightly translucent. ([#1364](https://github.com/mapbox/mapbox-navigation-ios/pull/1364))
* Fixed an issue preventing `NavigationViewController.navigationMapView(_:simplifiedShapeDescribing:)` (now `NavigationViewController.navigationMapView(_:simplifiedShapeFor:)`) from being called. ([#1413](https://github.com/mapbox/mapbox-navigation-ios/pull/1413))

### Spoken instructions

* Fixed an issue causing the wrong instructions to be spoken. ([#1396](https://github.com/mapbox/mapbox-navigation-ios/pull/1396))

### User location

* The `RouteController.routeProgress` property is now available in Objective-C. ([#1323](https://github.com/mapbox/mapbox-navigation-ios/pull/1323))
* Added a `RouteController.tunnelSimulationEnabled` option that keeps the user location indicator moving steadily while the user travels through a tunnel and GPS reception is unreliable. ([#1218](https://github.com/mapbox/mapbox-navigation-ios/pull/1218))

### Other changes

* `DistanceFormatter`, `ReplayLocationManager`, `SimulatedLocationManager`, `LanesView`, and `ManueverView` are now subclassable. ([#1345](https://github.com/mapbox/mapbox-navigation-ios/pull/1345]))
* Renamed many `NavigationViewController` and `NavigationMapViewDelegate` methods ([#1364](https://github.com/mapbox/mapbox-navigation-ios/pull/1364), [#1338](https://github.com/mapbox/mapbox-navigation-ios/pull/1338), [#1318](https://github.com/mapbox/mapbox-navigation-ios/pull/1318), [#1378](https://github.com/mapbox/mapbox-navigation-ios/pull/1378), [#1413](https://github.com/mapbox/mapbox-navigation-ios/pull/1413)):
    * `NavigationViewControllerDelegate.navigationViewControllerDidCancelNavigation(_:)` to `NavigationViewControllerDelegate.navigationViewControllerDidDismiss(_:byCanceling:)`
    * `-[MBNavigationViewControllerDelegate navigationViewController:didArriveAt:]` to `-[MBNavigationViewControllerDelegate navigationViewController:didArriveAtWaypoint:]` in Objective-C
    * `NavigationViewControllerDelegate.navigationMapView(_:routeStyleLayerWithIdentifier:source:)` to `NavigationViewControllerDelegate.navigationViewController(_:routeStyleLayerWithIdentifier:source:)`
    * `NavigationViewControllerDelegate.navigationMapView(_:routeCasingStyleLayerWithIdentifier:source:)` to `NavigationViewControllerDelegate.navigationViewController(_:routeCasingStyleLayerWithIdentifier:source:)`
    * `NavigationViewControllerDelegate.navigationMapView(_:shapeFor:)` to `NavigationViewControllerDelegate.navigationViewController(_:shapeFor:)`
    * `NavigationViewControllerDelegate.navigationMapView(_:simplifiedShapeFor:)` to `NavigationViewControllerDelegate.navigationViewController(_:simplifiedShapeFor:)`
    * `NavigationViewControllerDelegate.navigationMapView(_:waypointStyleLayerWithIdentifier:source:)` to `NavigationViewControllerDelegate.navigationViewController(_:waypointStyleLayerWithIdentifier:source:)`
    * `NavigationViewControllerDelegate.navigationMapView(_:waypointSymbolStyleLayerWithIdentifier:source:)` to `NavigationViewControllerDelegate.navigationViewController(_:waypointSymbolStyleLayerWithIdentifier:source:)`
    * `NavigationViewControllerDelegate.navigationMapView(_:shapeFor:legIndex:)` to `NavigationViewControllerDelegate.navigationViewController(_:shapeFor:legIndex:)`
    * `NavigationViewControllerDelegate.navigationMapView(_:didTap:)` to `NavigationViewControllerDelegate.navigationViewController(_:didSelect:)`
    * `NavigationViewControllerDelegate.navigationMapView(_:imageFor:)` to `NavigationViewControllerDelegate.navigationViewController(_:imageFor:)`
    * `NavigationViewControllerDelegate.navigationMapView(_:viewFor:)` to `NavigationViewControllerDelegate.navigationViewController(_:viewFor:)`
    * `NavigationViewControllerDelegate.navigationViewController(_:didSend:feedbackType:)` to `NavigationViewControllerDelegate.navigationViewController(_:didSendFeedbackAssigned:feedbackType:)`
    * `-[MBNavigationViewControllerDelegate navigationViewController:shouldDiscard:]` to `-[MBNavigationViewControllerDelegate navigationViewController:shouldDiscardLocation:]` in Objective-C
    * `-[MBNavigationViewControllerDelegate navigationViewController:roadNameAt:]` to `-[MBNavigationViewControllerDelegate navigationViewController:roadNameAtLocation:]`
    * `NavigationMapViewDelegate.navigationMapView(_:shapeDescribing:)` to `NavigationMapViewDelegate.navigationMapView(_:shapeFor:)`.
    * `NavigationMapViewDelegate.navigationMapView(_:simplifiedShapeDescribing:)` to `NavigationMapViewDelegate.navigationMapView(_:simplifiedShapeFor:)`.
    * `-[MBNavigationMapViewDelegate navigationMapView:shapeDescribingWaypoints:legIndex:]` to `-[MBNavigationMapViewDelegate navigationMapView:shapeForWaypoints:legIndex:]` in Objective-C
* `RouteController.recordFeedback(type:description:)` now returns a `UUID` instead of a string. Some `RouteController` methods have been renamed to accept `UUID`s as arguments instead of strings. ([#1413](https://github.com/mapbox/mapbox-navigation-ios/pull/1413))
* Renamed `TunnelIntersectionManagerDelegate.tunnelIntersectionManager(_:willEnableAnimationAt:callback:)` to `TunnelIntersectionManagerDelegate.tunnelIntersectionManager(_:willEnableAnimationAt:completionHandler:)` and `TunnelIntersectionManagerDelegate.tunnelIntersectionManager(_:willDisableAnimationAt:callback:)` to `TunnelIntersectionManagerDelegate.tunnelIntersectionManager(_:willDisableAnimationAt:completionHandler:)`. ([#1413](https://github.com/mapbox/mapbox-navigation-ios/pull/1413))

## v0.16.2 (April 13, 2018)

* Fixed a compiler error after installing the SDK using CocoaPods. ([#1296](https://github.com/mapbox/mapbox-navigation-ios/pull/1296))

## v0.16.1 (April 9, 2018)

### User interface

* Draws slight right and left turn icons for slight turns in the turn lane view. [#1270](https://github.com/mapbox/mapbox-navigation-ios/pull/1270)

### Core Navigation

* Fixed a crash that was caused by check the edit distance of an empty string. [#1281](https://github.com/mapbox/mapbox-navigation-ios/pull/1281/)
* Removes warnings when using Swift 4.1. [#1271](https://github.com/mapbox/mapbox-navigation-ios/pull/1271)

### Spoken instructions

* Fixed an issue that would preemptively fallback to the default speech synthesizer. [#1284](https://github.com/mapbox/mapbox-navigation-ios/pull/1284)

## v0.16.0 (March 26, 2018)

### User interface
* While the user travels through a tunnel, `NavigationMapView` temporarily applies a night style (a style whose `styleType` property is set to `StyleType.night`). ([#1127](https://github.com/mapbox/mapbox-navigation-ios/pull/1127))
* The user can reveal the list of upcoming steps by swiping downward from the top banner. ([#1150](https://github.com/mapbox/mapbox-navigation-ios/pull/1150))
* Renamed `StyleType.dayStyle` and `StyleType.nightStyle` to `StyleType.day` and `StyleType.night`, respectively. ([#1250](https://github.com/mapbox/mapbox-navigation-ios/pull/1250))
* Fixed an issue causing the overview map to insist on centering the route upon each location update. ([#1223](https://github.com/mapbox/mapbox-navigation-ios/pull/1223))
* Improved the contrast of `TimeRemainingLabel.trafficSevereColor` against `BottomBannerView.backgroundColor` in `NightStyle`. ([#1228](https://github.com/mapbox/mapbox-navigation-ios/pull/1228))
* Fixed an issue where a slash appeared between two shields in the top banner. ([#1169](https://github.com/mapbox/mapbox-navigation-ios/pull/1169))
* Fixed an issue where using `NavigationMapViewControllerDelegate.navigationMapView(_:imageFor:)` would not override the destination annotation. ([#1256](https://github.com/mapbox/mapbox-navigation-ios/pull/1256))
* Adds a handle at the bottom of the banner to reveals additional instructions. ([#1253](https://github.com/mapbox/mapbox-navigation-ios/pull/1253))

### Spoken instructions
* Audio data for spoken instructions is cached in device storage to minimize data usage. ([#12296](https://github.com/mapbox/mapbox-navigation-ios/pull/1226))

### Core Navigation
* Renamed the `RouteController.reroutesOpportunistically` property to `RouteController.reroutesProactively`, `RouteControllerOpportunisticReroutingInterval` global variable to `RouteControllerProactiveReroutingInterval`, and the `RouteControllerNotificationUserInfoKey.isOpportunisticKey` value to `RouteControllerNotificationUserInfoKey.isProactiveKey`. ([#1230](https://github.com/mapbox/mapbox-navigation-ios/pull/1230))
* Added a `RouteStepProgress.currentIntersection` property that is set to the intersection the user has most recently passed along the route. ([#1127](https://github.com/mapbox/mapbox-navigation-ios/pull/1127))
* Fixed an issue where the `RouteStepProgress.upcomingIntersection` property was always set to the current step’s first intersection. ([#1127](https://github.com/mapbox/mapbox-navigation-ios/pull/1127))
* Added support for using the Mapbox Map Matching API. [#1177](https://github.com/mapbox/mapbox-navigation-ios/pull/1177)

### Other changes
* Added Arabic and European Portuguese localizations. ([#1252](https://github.com/mapbox/mapbox-navigation-ios/pull/1251))

## v0.15.0 (March 13, 2018)

#### Breaking changes
* `NavigationMapViewDelegate` and `RouteMapViewControllerDelegate`: `navigationMapView(_:didTap:)` is now `navigationMapView(_:didSelect:)` [#1063](https://github.com/mapbox/mapbox-navigation-ios/pull/1063)
* The Constants that concern Route-Snapping logic have been re-named. The new names are: `RouteSnappingMinimumSpeed`, `RouteSnappingMaxManipulatedCourseAngle`, and `RouteSnappingMinimumHorizontalAccuracy`.

#### User interface
* `StepsViewController` 's convenience initializer (`StepsViewController.init(routeProgress:)`) is now public. ([#1167](https://github.com/mapbox/mapbox-navigation-ios/pull/1167))
* Fixed an issue preventing the distance from appearing in the turn banner when the system language was set to Hebrew and the system region was set to Israel or any other region that uses the metric system. ([#1176](https://github.com/mapbox/mapbox-navigation-ios/pull/1176))
* Various views and view controllers correctly mirror right-to-left in Hebrew. ([#1182](https://github.com/mapbox/mapbox-navigation-ios/pull/1182))

#### Core Navigation
* `RoteController` now has a new property, `snappedLocation`. This property represents the raw location, snapped to the current route, if applicable. If not applicable, the value is `nil`.
* `RouteController`'s `MBRouteControllerProgressDidChange` notification now exposes the raw location in it's update, accessible by `MBRouteControllerRawLocationKey`

#### Voice guidance

* Fixed an issue that caused `RouteVoiceController` and `MabpboxVoiceController` to speak over one another. [#1213](https://github.com/mapbox/mapbox-navigation-ios/pull/1213)

#### Other changes
* Fixed a crash while navigating that affected applications that do not use Mapbox-hosted styles or vector tiles. [#1183](https://github.com/mapbox/mapbox-navigation-ios/pull/1183)
* The `DistanceFormatter.attributedString(for:)` method is now implemented. It returns an attributed string representation of the distance in which the `NSAttributedStringKey.quantity` attribute is applied to the numeric quantity. ([#1176](https://github.com/mapbox/mapbox-navigation-ios/pull/1176))
* Fixed an issue in which turn lanes were displayed in the wrong order when the system language was set to Hebrew. ([#1175](https://github.com/mapbox/mapbox-navigation-ios/pull/1175))

## v0.14.0 (February 22, 2018)

#### Breaking changes

* Removed the dependency on AWSPolly. Voice announcements are now coming directly from Mapbox and for free for all developers. Because of this, PollyVoiceController has been removed.  [#617](https://github.com/mapbox/mapbox-navigation-ios/pull/617)
* MapboxDirections.swift version 0.17.x is now required. [#1085](https://github.com/mapbox/mapbox-navigation-ios/pull/1085)
* Removed the key `RouteControllerNotificationUserInfoKey.estimatedTimeUntilManeuverKey` from `.routeControllerProgressDidChange`. Please use `durationRemaining` instead which can be found on the `RouteProgress`. [#1126](https://github.com/mapbox/mapbox-navigation-ios/pull/1126/)
* Renamed notification names associated with `RouteController` in Objective-C code. [#1122](https://github.com/mapbox/mapbox-navigation-ios/pull/1122)
* The user info keys of `RouteController`-related notifications have been renamed and are now members of the `RouteControllerNotificationUserInfoKey` struct in Swift and the `MBRouteControllerNotificationUserInfoKey` extensible enumeration in Objective-C. [#1122](https://github.com/mapbox/mapbox-navigation-ios/pull/1122)

<details>
<summary>Here is reference for the new notification names:</summary>
<br>
<table>
<thead>
<tr>
<th colspan="2">Swift</th>
<th colspan="2">Objective-C</th>
</tr>
<tr>
<th>Old</th>
<th>New</th>
<th>Old</th>
<th>New</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>Notification.Name.navigationSettingsDidChange</code></td>
<td><code>Notification.Name.navigationSettingsDidChange</code></td>
<td><code>MBNavigationSettingsDidChange</code></td>
<td><code>MBNavigationSettingsDidChangeNotification</code></td>
</tr>
<tr>
<td><code>Notification.Name.routeControllerProgressDidChange</code></td>
<td><code>Notification.Name.routeControllerProgressDidChange</code></td>
<td><code>MBRouteControllerNotificationProgressDidChange</code></td>
<td><code>MBRouteControllerProgressDidChangeNotification</code></td>
</tr>
<tr>
<td><code>Notification.Name.routeControllerDidPassSpokenInstructionPoint</code></td>
<td><code>Notification.Name.routeControllerDidPassSpokenInstructionPoint</code></td>
<td><code>MBRouteControllerDidPassSpokenInstructionPoint</code></td>
<td><code>MBRouteControllerDidPassSpokenInstructionPointNotification</code></td>
</tr>
<tr>
<td><code>Notification.Name.routeControllerWillReroute</code></td>
<td><code>Notification.Name.routeControllerWillReroute</code></td>
<td><code>MBRouteControllerWillReroute</code></td>
<td><code>MBRouteControllerWillRerouteNotification</code></td>
</tr>
<tr>
<td><code>Notification.Name.routeControllerDidReroute</code></td>
<td><code>Notification.Name.routeControllerDidReroute</code></td>
<td><code>MBRouteControllerDidReroute</code></td>
<td><code>MBRouteControllerDidRerouteNotification</code></td>
</tr>
<tr>
<td><code>Notification.Name.routeControllerDidFailToReroute</code></td>
<td><code>Notification.Name.routeControllerDidFailToReroute</code></td>
<td><code>MBRouteControllerDidFailToReroute</code></td>
<td><code>MBRouteControllerDidFailToRerouteNotification</code></td>
</tr>
<tr>
<td><code>RouteControllerProgressDidChangeNotificationProgressKey</code></td>
<td><code>RouteControllerNotificationUserInfoKey.routeProgressKey</code></td>
<td><code>MBRouteControllerProgressDidChangeNotificationProgressKey</code></td>
<td><code>MBRouteControllerRouteProgressKey</code></td>
</tr>
<tr>
<td><code>RouteControllerProgressDidChangeNotificationLocationKey</code></td>
<td><code>RouteControllerNotificationUserInfoKey.locationKey</code></td>
<td><code>MBRouteControllerProgressDidChangeNotificationLocationKey</code></td>
<td><code>MBRouteControllerLocationKey</code></td>
</tr>
<tr>
<td><code>RouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey</code></td>
<td>🚮 (removed)</td>
<td><code>MBRouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey</code></td>
<td>🚮 (removed)</td>
</tr>
<tr>
<td><code>RouteControllerNotificationLocationKey</code></td>
<td><code>RouteControllerNotificationUserInfoKey.locationKey</code></td>
<td><code>MBRouteControllerNotificationLocationKey</code></td>
<td><code>MBRouteControllerLocationKey</code></td>
</tr>
<tr>
<td><code>RouteControllerNotificationRouteKey</code></td>
<td>🚮 (unused)</td>
<td><code>MBRouteControllerNotificationRouteKey</code></td>
<td>🚮 (unused)</td>
</tr>
<tr>
<td><code>RouteControllerNotificationErrorKey</code></td>
<td><code>RouteControllerNotificationUserInfoKey.routingErrorKey</code></td>
<td><code>MBRouteControllerNotificationErrorKey</code></td>
<td><code>MBRouteControllerRoutingErrorKey</code></td>
</tr>
<tr>
<td><code>RouteControllerDidFindFasterRouteKey</code></td>
<td><code>RouteControllerNotificationUserInfoKey.isOpportunisticKey</code></td>
<td><code>MBRouteControllerDidFindFasterRouteKey</code></td>
<td><code>MBRouteControllerIsOpportunisticKey</code></td>
</tr>
<tr>
<td><code>RouteControllerDidPassSpokenInstructionPointRouteProgressKey</code></td>
<td><code>RouteControllerNotificationUserInfoKey.routeProgressKey</code></td>
<td><code>MBRouteControllerDidPassSpokenInstructionPointRouteProgressKey</code></td>
<td><code>MBRouteControllerRouteProgressKey</code></td>
</tr>
</tbody>
</table>
</details>

## Core Navigation

* Location updates sent via `.routeControllerProgressDidChange` are now always sent as long as the location is qualified. [#1126](https://github.com/mapbox/mapbox-navigation-ios/pull/1126/)
* Exposes `setOverheadCameraView(from:along:for:)` which is useful for fitting the camera to an overhead view for the remaining route coordinates.
* Changed the heuristics needed for a the users location to unsnap from the route line. [#1110](https://github.com/mapbox/mapbox-navigation-ios/pull/1122)
* Changes `routeController(:didDiscardLocation:)` to `routeController(:shouldDiscardLocation:)`. Now if implemented, developers can choose to keep a location when RouteController deems a location unqualified. [#1095](https://github.com/mapbox/mapbox-navigation-ios/pull/1095/)

## User interface

* Added a `NavigationMapView.localizeLabels()` method that should be called within `MGLMapViewDelegate.mapView(_:didFinishLoading:)` for standalone `NavigationMapView`s to ensure that map labels are in the correct language. [#1111](https://github.com/mapbox/mapbox-navigation-ios/pull/1122)
* The `/` delimiter is longer shown when a shield is shown on either side of the delimiter. This also removes the dependency SDWebImage. [#1046](https://github.com/mapbox/mapbox-navigation-ios/pull/1046)
* Exposes constants used for styling the route line. [#1124](https://github.com/mapbox/mapbox-navigation-ios/pull/1124/)
* Exposes `update(for:)` on `InstructionBannerView`. This is helpful for developers creating a custom user interface. [#1085](https://github.com/mapbox/mapbox-navigation-ios/pull/1085/)

## Voice guidance

* Exposes `RouteVoiceController.speak(_:)` which would allow custom subclass of MapboxVoiceController to override this method and pass a modified SpokenInstruction to our superclass implementation.


## v0.13.1 (February 7, 2018)

### Core Navigation

* Fixes a bug where the `spokenInstructionIndex` was incremented beyond the number of instructions for a step. (#1080)
* Fixed a bug that crashed when navigating beyond the final waypoint. (#1087)
* Added `NavigationSettings.distanceUnit` to let a user override the default unit of measurement for the device’s region setting. (#1055)

### User interface

* Added support for spoken instructions in Danish. (#1041)
* Updated translations for Russian, Swedish, Spanish, Vietnamese, Hebrew, Ukrainian, and German. (#1064)
* Fixed a bug that prevented the user puck from laying flat when rotating the map. (#1090)
* Updated translations for Russian, Swedish, Spanish, Vietnamese, Hebrew, Ukrainian, and German. (#1064) (#1089)

## v0.13.0 (January 22, 2018)

### Packaging

* Upgraded to MapboxDirections.swift [v0.16.0](https://github.com/mapbox/MapboxDirections.swift/releases/tag/v0.16.0), which makes `ManeuverType`, `ManeuverDirection`, and `TransportType` non-optional. (#1040)
* Added Danish and Hebrew localizations. (#1031, #1043)

### User location

* Removed `RouteControllerDelegate.routeController(_:shouldIncrementLegWhenArrivingAtWaypoint:)` and `NavigationViewControllerDelegate.navigationViewController(_:shouldIncrementLegWhenArrivingAtWaypoint:)`. `RouteControllerDelegate.routeController(_:didArriveAt:)` and `NavigationViewControllerDelegate.navigationViewController(_:didArriveAt:)` now return a Boolean that determines whether the route controller automatically advances to the next leg of the route. (#1038)
* Fixed an issue where `NavigationViewControllerDelegate.navigationViewController(_:didArriveAt:)` was called twice at the end of the route. (#1038)
* Improved the reliability of user location tracking when several location updates arrive simultaneously. (#1021)

### User interface

* Removed the `WayNameView` class in favor of `WayNameLabel` and renamed the `LanesContainerView` class to `LanesView`. (#981 )
* Added a `NavigationMapView.tracksUserCourse` property for enabling course tracking mode when using the map view independently of `NavigationViewController`. (#1015)

## v0.12.2 (January 12, 2018)

Beginning with this release, we’ve compiled [a set of examples](https://www.mapbox.com/mapbox-navigation-ios/navigation/0.12.2/Examples.html) showing how to accomplish common tasks with this SDK. You can also check out the [navigation-ios-examples](https://github.com/mapbox/navigation-ios-examples) project and run the included application on your device.

### User interface

* Fixed a crash loading `NavigationViewController`. (#977)
* Fixed issues causing the user puck to animate at the wrong framerate while the device is unplugged. (#970)
* Fixed unexpected behavior that occurred if only one `Style` was specified when initializing `NavigationViewController`. (#990)

### Core Navigation

* If `RouteController` initially follows an alternative route, it now attempts to follow the most similar route after rerouting. (#995)
* Fixed an issue preventing the `RouteControllerDelegate.routeController(_:didArriveAt:)` method from being called if `navigationViewController(_:shouldIncrementLegWhenArrivingAtWaypoint:)` was unimplemented. (#984)
* Added a `VoiceControllerDelegate.voiceController(_:willSpeak:routeProgress:)` method for changing spoken instructions on an individual basis. (#988)

## v0.12.1 (January 6, 2018)

### User interface

* Fixed an issue where the “then” banner appeared at the wrong times. (#957)
* Fixed an issue where the user location view spun around at the end of a leg. (#966)

### Core Navigation

* Fixed an issue that triggered unnecessary reroutes. (#959)
* The `RouteControllerDelegate.routeController(_:didArriveAt:)` method is now called when arriving at any waypoint, not just the last waypoint. (#972)
* Added a `RouteController.setEndOfRoute(_:comment:)` method for collecting feedback about the route before the user cancels it. (#965)

## v0.12.0 (December 21, 2017)

### Breaking changes 🚨

* If you install this SDK using Carthage, you must now include each of this SDK’s dependencies in your Run Script build phase: AWSCore.framework, AWSPolly.framework, Mapbox.framework, MapboxDirections.framework, MapboxMobileEvents.framework, Polyline.framework, SDWebImage.framework, Solar.framework, and Turf.framework. These dependencies are no longer embedded inside MapboxNavigation.framework. See [the Carthage documentation](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos) for details. (#930)
* This library no longer depends on [OSRM Text Instructions for Swift](https://github.com/Project-OSRM/osrm-text-instructions.swift/). If you have previously installed this SDK using Carthage, you may need to remove OSRMTextInstructions.framework from a Run Script build step. (#925)
* Notification names are now members of `Notification.Name`. (#943)

### User interface

* When the user approaches the final waypoint, a panel appears with options for sending feedback about the route. (#848)
* Fixed an issue preventing the “Then” banner from appearing. (#940)
* Fixed an issue that sometimes prevented the night style from being applied. (#904)
* The turn banner’s labels and route shield images are now derived from the Directions API response. (#767)
* Roundabout icons in the turn banner now go clockwise in regions that drive on the left. (#911)
* Fixed an issue that turned the estimated arrival time to black when traffic congestion data was unavailable. (#912)
* Added a Bulgarian localization. [Help us speak your language!](https://www.transifex.com/mapbox/mapbox-navigation-ios/) (#954)
* Updated Dutch, Spanish, Swedish, and Vietnamese translations. (#944)

### Voice guidance

* Tapping the mute button immediately silences any current announcement. (#936)
* Improved announcements near roundabouts and rotaries when using `NavigationRouteOptions`. You can also set the `RouteOptions.includesExitRoundaboutManeuver` property manually to take advantage of this improvement. (#945)
* You can customize the AWS region used for Amazon Polly spoken instructions using the `PollyVoiceController(identityPoolId:regionType:)` initializer. (#914)
* Certain roads [tagged with pronunciations in OpenStreetMap](https://wiki.openstreetmap.org/wiki/Key:name:pronunciation) are pronounced correctly when Amazon Polly is unavailable. (#624)
* Refined the appearance of the spoken instruction map labels that are enabled via the `NavigationViewController.annotatesSpokenInstructions` property. (#907)

### User location

* When `SimulatedLocationManager` is active, the user can swipe on the “Simulating Navigation” banner to adjust the rate of travel. (#915)
* Fixed unnecessary rerouting that sometimes occurred if the user advanced to a subsequent step earlier than expected. (#910)
* If your application’s Info.plist file lacks a location usage description, `NavigationViewController` will immediately fail a `precondition`. (#947)

## v0.11.0 (November 29, 2017)

Beginning with this release, the navigation SDK and Core Navigation are written in Swift 4 (#663).

### Feedback

* Removed the audio feedback recording feature. You no longer need to add an `NSMicrophoneUsageDescription` to your Info.plist. (#870)
* The Report Feedback button no longer appears after rerouting if `NavigationViewController.showsReportFeedback` is disabled. (#890)

### User interface

* Added a `StepsViewController` class for displaying the route’s upcoming steps in a table view. (#869)
* The bottom bar is more compact in landscape orientation. (#863)
* Fixed an issue where the “then” banner appeared too soon. (#865)
* Maneuver arrows are no longer shown for arrival maneuvers. (#884)
* Fixed a crash that sometimes occurred after returning to the application from the background. (#888)

### Voice guidance

* A new `RouteVoiceController.voiceControllerDelegate` property lets an object conforming to the `VoiceControllerDelegate` protocol know when a spoken instruction fails or gets interrupted by another instruction. (#800, #864)

### User location

* Fixed an issue that sometimes prevented `NavigationViewControllerDelegate.navigationViewController(_:didArriveAt:)` from getting called. (#883)
* Fixed an issue where the user location indicator floated around when starting a new leg. (#886)

## v0.10.1 (November 16, 2017)

### Packaging

* Reverts a change that used AWS's repo for the Polly dependency. This will help with build times when using Carthage. #859
* Updates Polly dependency to v2.6.5 #859

### Views

* Aligns the instruction banner and the next banner better. #860
* Fixes a bug on `InstructionsBannerView` and `StepInstructionsView` that prevented them from being styleable. #852
* Fixes a few minor styleable elements on `DayStyle` and `NightStyle`. #858

### Map

* `MGLMapView init(frame:styleURL:)` is exposed again on `NavigationMapView`. #850

### User location tracking

* The refresh rate of the user puck remains throttled if the upcoming step is straight. #845

### Feedback

* The `Report Feedback` button after rerouting is only displayed for 5 seconds. #853

## v0.10.0 (November 13, 2017)

### Packaging

* Xcode 9 is required for building the navigation SDK or Core Navigation. (#786)
* Added German and Dutch localizations. [Help us speak your language!](https://www.transifex.com/mapbox/mapbox-navigation-ios/dashboard/) (#778)
* To build and run the provided sample applications, you now have the option to create a plain text file named .mapbox containing a Mapbox access token and place it in your home folder. The SDK will read this file and automatically populate the `MGLMapboxAccessToken` of the `Info.plist` at build-time. (#817)

### Instruction banner

* Improved `NavigationViewController`’s layout on iPhone X. (#786, #816)
* Refined the turn banner’s appearance. (#745, #788)
* Added a reusable `InstructionBannerView` class that represents the turn banner. (#745)
* Route shields are displayed inline with road or place names in `InstructionBannerView`. (#745)
* When another step follows soon after the upcoming step, that subsequent step appears in a smaller banner beneath the main turn banner. (#819)

### Map

* The map zooms in and out dynamically to show more of the road ahead. (#769, #781)
* Replaced `NavigationMapView.showRoute(_:)` with `NavigationMapView.showRoutes(_:legIndex:)`, which can show alternative routes on the map. (#789)
* Added a `NavigationMapViewDelegate.navigationMapView(_:didSelect:)` method to respond to route selection on the map. (#789, #806)
* Added a `NavigationMapViewDelegate.navigationMapView(_:didSelect:)` method to respond to waypoint selection on the map. (#806)
* Fixed a bug preventing legs beyond the third waypoint from appearing. (#807)
* Decreased the map’s animation frame rate for improved battery life. (#760)

### Voice guidance

* Spoken instructions are determined by Directions API responses. (#614)
* When Polly is enabled, audio for spoken instructions is fetched over the network ahead of time, reducing latency. (#724, #768)
* The `NavigationViewController.annotatesSpokenInstructions` property, disabled by default, makes it easier to see where instructions will be read aloud along the route for debugging purposes. (#727, #826)
* Fixed an issue preventing `PollyVoiceController` from ducking background audio while the device is muted using the physical switch. (#805)

### User location tracking

* Fixed an issue causing poor user location tracking on iPhone X. (#833)
* The user location indicator is more stable while snapped to the route line. (#754)
* Renamed `RouteController.checkForFasterRouteInBackground` to `RouteController.reroutesOpportunistically`. (#826)
* Added a `RouteControllerOpportunisticReroutingInterval` constant for configuring the interval between opportunistic rerouting attempts. (#826)

### Feedback

* The `NavigationViewController.recordsAudioFeedback` property, disabled by default, allows the user to dictate feedback by long-pressing on a feedback item. This option requires the `NSMicrophoneUsageDescription` Info.plist option. (#719, #826)
* Options in the feedback interface are easier to discern from each other. (#761)
* Fixed an issue where the feedback interface appeared automatically after rerouting. (#749)
* Rearranged the feedback options. (#770, #779)

## v0.9.0 (October 17, 2017)

* `NavigationMapView` uses a custom course tracking mode created from the ground up. The view representing the user’s location (the “user puck”) is larger and easier to see at a glance, and it continues to point in the user’s direction of travel even in Overview mode. To customize the user puck, use the `NavigationMapView.userCourseView` property. (#402)
* Fixed an issue causing the user puck to slide downward from the center of the screen when beginning a new route. (#402)
* You can customize the user puck’s location on screen by implementing the `NavigationViewControllerDelegate.navigationViewController(_:mapViewUserAnchorPoint:)` method. (#402)
* Improved user course snapping while not moving. (#718)
* Throttled the map’s frame rate while the device is unplugged. (#709)
* Fixed an issue causing the “Rerouting” banner to persist even after a new route is received. (#707)
* A local user notification is no longer posted when rerouting. (#708)

## v0.8.3 (October 9, 2017)

* Pins the dependency `Solar` to v2.0.0. This should fix some build issues. #693
* Increases the width of the upcoming maneuver arrow. #671
* Improved user location snapping. #679
* Improves simulation mode by using more accurate speeds. #683
* Adopted [Turf](https://github.com/mapbox/turf-swift). The `wrap(_:min:max:)` function has been removed; use Turf’s `CLLocationDirection.wrap(min:max:)` instead. #653
* Defaulted to `kCLLocationAccuracyBestForNavigation` for location accuracy. #670

## v0.8.2 (September 29, 2017)

* Fixed a bug which caused the upcoming maneuver label in night mode to have a white background (#667).
* Fixed a bug which caused audio announcements to be repeated over one another (#661,  #669).

## v0.8.1 (September 28, 2017)

* Fixed a build error that occurred if MapboxNavigation was installed via CocoaPods. (#632)
* The turn banner shows more of the upcoming road name before truncating. (#657)
* When entering a roundabout, the icon in the turn banner indicates the correct direction of travel. (#640)
* When beginning a new route, the SDK announces the initial road and direction of travel. (#654)
* Fixed an issue causing the user’s location to be snapped to the wrong part of the route near a U-turn. (#642)
* Core Navigation detects when the user performs a U-turn earlier than anticipated and promptly calculates a new route. (#646)
* If Amazon Polly is configured but unreachable, the SDK switches to AVSpeechSynthesizer sooner, before the instruction becomes outdated. (#652)
* When instructions are announced by Amazon Polly, [dynamic range compression](https://en.wikipedia.org/wiki/Dynamic_range_compression) is used to make the audio easier to hear over the din of a moving vehicle. (#635, #662)

## v0.8.0 (September 19, 2017)

### Location and guidance

* Fixed an issue causing steps to be linked together too frequently. (#573)
* On a freeway, an announcement is read aloud at ¼ mile ahead of a maneuver instead of ½ mile ahead. (#569)
* Separate instructions are given for entering and exiting a roundabout. (#561)
* Rerouting occurs more promptly when the user makes a wrong turn at an intersection. (#560)
* More unreliable location updates are filtered out. (#579)
* Improved how Polly pronounces some road names and numbers. (#618, #622)
* Instructions are read by the higher-quality [Alex](https://support.apple.com/en-us/HT203077) voice if it is installed and Polly is unconfigured or unavailable. (#612)

### User interface

* Adjusted the night style to take effect closer to sunset. (#584)
* Fixed an issue where the map bore a day style while the surrounding UI bore a night style. (#572)
* Fixed an issue causing some elements on the map to disappear when switching styles. (#570)
* Fixed an issue causing slight turns to look like regular turns in the turn banner. (#602)
* Large, named roundabouts are symbolized as roundabouts instead of simple intersections in the turn banner. (#574)
* Fixed an issue producing confusing lane arrows at a fork in the road. (#586)
* The notification for a completed maneuver is removed as the user completes that step. (#577)
* The distance in the turn banner changes at a more regular interval. (#626)
* Updated the appearance of various controls in turn-by-turn mode. (#578, #587, #588, #591)
* Arrows in the turn banner can have a different appearance than arrows in the step table. (#571)
* Fixed overly aggressive abbreviation of road names in the turn banner. (#616)
* Fixed an issue preventing road names in the turn banner from being abbreviated when certain punctuation was present. (#618)
* Fixed a crash that occurred when an attempt to calculate a new route failed. (#585)
* Fixed an issue preventing the estimated arrival time from being updated as the user is stuck in traffic. (#595)
* Fixed a crash that sometimes occurred when starting turn-by-turn navigation. (#607)
* Fixed a flash that occurred when rerouting. (#605)
* Fixed memory leaks. (#609, #628)

### Other changes

* Fixed strings in the Hungarian, Swedish, and Vietnamese localizations that had reverted to English. (#619)
* Updated translations in Catalan, Hungarian, Lithuanian, Russian, Spanish, Swedish, and Vietnamese. (#619)
* Added methods to `NavigationViewControllerDelegate` that indicate when the user is sending feedback. (#599)
* Fixed an issue where `DistanceFormatter.string(fromMeters:)` used the wrong units. (#613)

## v0.7.0 (August 30, 2017)

### Packaging

* Unpinned most dependencies to avoid various build issues introduced in v0.6.1. It is once again possible to use this SDK with the latest Mapbox iOS SDK. (#525)
* Added Russian, Slovenian, and Ukrainian localizations. (#505, #542)

### User interface

* `NavigationViewController` and its map automatically switch between daytime and nighttime styles. (#519)
* A banner appears when the device experiences weak GPS reception. (#490)
* A banner also appears when simulation mode is enabled. (#521)
* The time remaining in the bottom bar changes color based on the level of traffic congestion along the remaining route. (#403)
* Added `NavigationViewControllerDelegate.navigationMapView(_:viewFor:)` for providing a custom user location annotation and/or destination annotation. (#498)
* Moved various properties of `Style` to individual control classes. (#536)
* Added properties to `LaneArrowView` for customizing the appearance of lane indicators. (#490)
* Added a `Style.statusBarStyle` property for customizing the appearance of the status bar. (#512)
* A shield now appears in the turn banner on Puerto Rico routes. (#529)
* Fixed an issue preventing an arrow from appearing on the route line when the user swipes the turn banner to a future step. (#532)
* Fixed an issue causing the shield in the turn banner to go blank when the user swipes the turn banner backward. (#506)
* Fixed an issue that caused the camera to stutter when completing a maneuver. (#520)
* Fixed an issue causing the turn banner to remain on a future step after tapping Resume. (#508)
* Fixed an issue where the distance would sometimes be displayed as “0 mm”. (#517)
* Fixed a missing less-than sign in the bottom bar when little time remains on the step or route. (#527)

### Voice guidance

* Fixed an issue causing Polly to misread abbreviations such as “CR” in route numbers and letters such as “N” in street names. (#552)
* A tone is played when automatically switching to a faster route in the background. (#541)
* Polly now pronounces Italian instructions using an Italian voice. (#542)
* Fixed an issue preventing the SDK from falling back to AVFoundation when Polly is unavailable. (#544)
* Improved the wording of various instructions in Swedish. (Project-OSRM/osrm-text-instructions#138)
* The Spanish localization consistently uses _usted_ form. (Project-OSRM/osrm-text-instructions#137)

### Core Navigation

* A new `NavigationRouteOptions` class makes it easier to request a route optimized for turn-by-turn navigation. (#531)
* A trip can now consist of multiple legs. (#270)
* Added `SpokenInstructionFormatter` and `VisualInstructionFormatter` classes for turning `RouteStep`s into strings appropriate for speech synthesis and display, respectively. (#456)
* When the user is moving slowly, `RouteController` snaps the location and course to the route line more aggressively. (#540)
* `RouteController` more aggressively snaps the user’s location to the route line at greater distances than before. (#551)
* Added `NavigationLocationManager.automaticallyUpdatesDesiredAccuracy` to control whether the location manager’s desired accuracy changes based on the battery state. (#504)

## v0.6.1 (August 14, 2017)

* Pinned all dependencies to prevent downstream breaking changes from effecting this library. https://github.com/mapbox/mapbox-navigation-ios/commit/d5c7204b0c9f03564b634da5be135ae35930804c
* Improved the initial camera view when entering navigation. https://github.com/mapbox/mapbox-navigation-ios/pull/482
* Adds support for iPads in the example app. https://github.com/mapbox/mapbox-navigation-ios/pull/477
* Does a better job at unpacking Polly requests to prevent the UI from locking up. https://github.com/mapbox/mapbox-navigation-ios/pull/462
* Inaccurate locations are now filtered out. https://github.com/mapbox/mapbox-navigation-ios/pull/441
* Lanes are now only showed for `.high` and `.medium` alerts. https://github.com/mapbox/mapbox-navigation-ios/pull/444
* The reroute sound is not played when muted. https://github.com/mapbox/mapbox-navigation-ios/pull/450
* Adds a new `StatusView` for displaying reroute and location accuracy information. https://github.com/mapbox/mapbox-navigation-ios/commit/b942844c52c026342b6237186715468091c53c9a
* AlertLevel distances no longer incorporate user speed for knowing when to give an announcement. https://github.com/mapbox/mapbox-navigation-ios/pull/448

## v0.6.0 (July 28, 2017)

### Packaging

* By default, NavigationMapView displays the Navigation Guidance Day v2 style. A Navigation Preview Day v2 style (`mapbox://styles/mapbox/navigation-preview-day-v2`) is also available for applications that implement a preview map. (#387)
* By default, NavigationMapView now indicates the level of traffic congestion along each segment of the route line. (#359)
* Added Italian and Traditional Chinese localizations. [Help translate the SDK into your language!](https://www.transifex.com/mapbox/mapbox-navigation-ios/) (#413, #438)

### User interface

* A 🐞 button on the map allows the user to submit feedback about the current route. (#400)
* The turn banner and bottom bar display fractional mileages as decimal numbers instead of vulgar fractions. 🙊🙉 (#383)
* If a step leads to a freeway or freeway ramp, the turn banner generally displays a [control city](https://en.wikipedia.org/wiki/Control_city) or a textual representation of the route number (alongside the existing shield) instead of the freeway name. (#410, #417)
* As the user arrives at a waypoint, the turn banner displays the waypoint’s name instead of whitespace. (#419)
* The route line is now wider by default, to accommodate traffic congestion coloring. (#390)
* Moved the `snapsUserLocationAnnotationToRoute` property from RouteController to NavigationViewController. (#408)
* The road name label at the bottom of the map continues to display the current road name after the user ventures away from the route. (#408)
* If the upcoming maneuver travels along a [bannered route](https://en.wikipedia.org/wiki/Special_route), the parent route shield is no longer displayed in the turn banner. (#431)
* Fixed an issue causing the Mapbox logo to peek out from under the Recenter button. (#424)

### Voice guidance

* Suppressed the voice announcement upon rerouting if the first step of the new route is sufficiently long. (#395)
* The rerouting audio cue now unducks other applications’ audio afterwards. (#394)
* If a step leads to a freeway or freeway ramp, voice announcements for the step generally omit the name in favor of the route number. (#404, #412)
* Fixed an issue causing Amazon Polly to read parentheses aloud. (#418)

### Navigation

* Various methods of `NavigationMapViewDelegate` have more descriptive names in Objective-C. (#408)
* Fixed an issue causing `NavigationViewControllerDelegate.navigationViewController(_:didArriveAt:)` to be called twice in a row. (#414)
* Fixed a memory leak. (#399)

### Core Navigation

* Added a `RouteController.location` property that represents the user’s location snapped to the route line. (#408)
* Added a `RouteController.recordFeedback(type:description:)` method for sending user feedback to Mapbox servers. (#304)
* Fixed excessive rerouting while the user is located away from the route, such as in a parking lot. (#386)
* Fixed an issue where RouteController sometimes got stuck on slight turn maneuvers. (#378)
* When rerouting, Core Navigation connects to the same API endpoint with the same access token that was used to obtain the original route. (#405)
* The `ReplayLocationManager.location` and `SimulatedLocationManager.location` properties now return simulated locations instead of the device’s true location as reported by Core Location. (#411)
* You can enable the `RouteController.checkForFasterRouteInBackground` property to have Core Navigation periodically check for a faster route in the background. (#346)
* Fixed an issue preventing the `RouteControllerAlertLevelDidChange` notification from posting when transitioning from a high alert level on one step to a high alert level on another step. (#425)
* Improved the accuracy of location updates while the device is plugged in. (#432)
* Added anonymized metrics collection around significant events such as rerouting. This data will be used to improve the quality of Mapbox’s products, including the underlying OpenStreetMap road data, the Mapbox Directions API, and Core Navigation. (#304)

## v0.5.0 (July 13, 2017)

### Packaging

* The map now uses a style specifically designed for turn-by-turn navigation. (#263)
* Added French, Hungarian, Lithuanian, Persian, and Spanish localizations. [Help translate the SDK into your language!](https://www.transifex.com/mapbox/mapbox-navigation-ios/) (#351)
* Upgraded to [OSRM Text Instructions v0.2.0](https://github.com/Project-OSRM/osrm-text-instructions.swift/releases/tag/v0.2.0) with localization improvements and support for upcoming exit numbers provided by the Directions API. (#348)
* Corrected the frameworks’ bundle identifiers. (#281)

### User interface

* The turn banner now indicates when the SDK is busy fetching a new route. (#269)
* More interface elements are now styleable. The `Style.fontFamily` property makes it easy to set the entire interface’s font face. (#330)
* The interface now supports Dynamic Type. (#330)
* Fixed an issue preventing the turn banner from displaying the distance to some freeway exits. (#262)
* Fixed an issue in which swiping the turn banner to the right caused NavigationViewController to navigate to the wrong step. (#266)
* Fixed a crash presenting NavigationViewController via a storyboard segue. (#314)
* Fixed an issue causing black lines to appear over all roads during turn-by-turn navigation. (#339)
* When `NavigationViewController.route` is set to a new value, the UI updates to reflect the new route. (#302)
* Widened the route line for improved visibility. (#358)
* Fixed an issue causing maneuver arrows along the route line to appear malformed. (#284)
* Maneuver arrows no longer appear along the route line when the map is zoomed out. (#295)
* The turn banner more reliably displays a route shield for applicable freeway on- and off-ramps. (#353)
* Fixed an issue causing the turn banner to show a shield for the wrong step after swiping between steps. (#290)
* Fixed an issue causing NavigationViewController and voice alerts to stop updating after a modal view controller is pushed atop NavigationViewController. (#306)
* The map displays attribution during turn-by-turn navigation. (#288)
* Added a `NavigationMapViewControllerDelegate.navigationMapView(_:imageFor:)` method for customizing the destination annotation. (#268)
* Fixed an issue where the wrong source was passed into `MGLMapViewDelegate.navigationMapView(_:routeCasingStyleLayerWithIdentifier:source:)`. (#265, #267)
* The turn banner abbreviates road names when using the Catalan, Lithuanian, Spanish, Swedish, or Vietnamese localization. (#254, #376)

### Voice guidance

* To use Amazon Polly for voice guidance, set the `NavigationViewController.voiceController` property. (#313)
* Fixed an issue that disabled Polly-powered voice guidance when the application went to the background. A message is printed to the console if the `audio` background mode is missing from the application’s Info.plist file. (#356)
* Fixed a crash that could occur when the device is muted and an instruction would normally be read aloud. (#275)
* By default, a short audio cue now plays when the user diverges from the route, requiring a new route to be fetched. (#269)
* Renamed `RouteStepFormatter.string(for:markUpWithSSML:)` to `RouteStepFormatter.string(for:legIndex:numberOfLegs:markUpWithSSML:)`. (#348)

### Navigation

* Fixed a crash after a simulated route causes the SDK to fetch a new route. (#344)
* Fixed an issue that stopped location updates after the application returned to the foreground from the background. (#343)
* Fixed excessive calls to `NavigationViewControllerDelegate.navigationViewController(_:didArriveAt:)`. (#347)
* Fixed crashes that occurred during turn-by-turn navigation. (#271, #336)
* Fixed a memory leak that occurs when `NavigationViewController.navigationDelegate` is set. (#316)

### Core Navigation

* RouteController now requests Always Location Services permissions if `NSLocationAlwaysAndWhenInUseUsageDescription` is set in Info.plist. (#342)
* RouteController now continues to track the user’s location after arriving at the destination. (#333)
* Fixed an issue causing RouteController to alternate rapidly between steps. (#258)
* The SimulatedLocationManager class now bridges to Objective-C. (#314)
* The DistanceFormatter class has been moved to Core Navigation. (#309)

## v0.4.0 (June 1, 2017)

### Packaging

* Documentation is now available in Quick Help and code completion for most classes and methods. (#250)
* Added Catalan, Swedish, and Vietnamese localizations. (#203)

### User interface

* A new class, `Style`, makes it easy to customize the SDK’s appearance and vary it by size class. (#162)
* Fixed an issue causing the road name in the turn banner to be truncated. The road name may be abbreviated to fit the allotted space. (#215)
* Enlarged the distance in the turn banner. (#217)
* A button at the top-left corner of the map view displays a live overview of the route. (#106)
* A small label at the bottom of the map view displays the name of the street along which the user is currently traveling. (#155)
* `NavigationViewController` automatically adopts the tint color of the view controller that presents it. (#176)
* The user can no longer swipe the turn banner left of the current step to “preview” already completed steps. (#223)
* The U-turn icon in the turn banner is no longer flipped horizontally in countries that drive on the right. (#243)
* Distances are now measured in imperial units when the user’s language is set to British English. (#246)

### Voice guidance

* Fixed an issue causing voice instructions to be delivered by an Australian English voice regardless of the user’s region. (#187, #245)
* Fixed an issue causing a “continue” instruction to be repeated multiple times along the step. (#238)
* A final voice instruction is no longer delivered when merging onto a highway. (#239)

### Core Navigation

* `RouteController` is now responsible for the basic aspects of rerouting, including fetching the new route. A new `RouteControllerDelegate` protocol (mirrored by `NavigationViewControllerDelegate`) has methods for preventing or reacting to a rerouting attempt. (#251)
* A notification is posted as soon as Core Navigation successfully receives a new route or fails to receive a new route. (#251)
* When rerouting, any remaining intermediate waypoints are preserved in the new route. (#251)
* Improved the timing and accuracy of rerouting attempts. (#202, #228)
* Fixed an issue preventing the route progress (and thus the progress bar) from completing as the user arrives at the destination. (#157)
* Fixed an issue that affected Core Navigation’s accuracy near maneuvers. (#185)
* A simulated route performs maneuvers more realistically than before. (#226)
* Fixed an issue preventing a simulated route from reaching the end of the route. (#244)
* Resolved some compiler warnings related to the location manager. (#190)

## v0.3.0 (April 25, 2017)

* Renamed `RouteViewController` to `NavigationViewController`. (#133)
* Replaced the `NavigationUI.routeViewController(for:)` method with the `NavigationViewController(for:)` initializer. (#133)
* Fixed compatibility with MapboxDirections.swift v0.9.0. This library now depends on MapboxDirections.swift v0.9.x. (#139)
* Fixed an issue causing the SDK to ignore certain routing options when rerouting the user. (#139)
* Added a `NavigationViewController.simulatesLocationUpdates` property that causes the SDK to simulate location updates along a route. (#111)
* Added a `NavigationViewControllerDelegate.navigationViewController(_:didArriveAt:)` method that gets called when user arrives at the destination. (#158)
* Added methods to NavigationViewControllerDelegate to customize the appearance and shape of the route line. (#135)
* Fixed an issue preventing the volume setting from working when using the built-in system speech synthesizer. (#160)
* Added support for Russian and Spanish voices when using Amazon Polly for voice alerts. (#153)

## v0.2.1 (April 15, 2017)

* This library now requires MapboxDirections.swift v0.8.x as opposed to v0.9.0, which is incompatible. ([#150](https://github.com/mapbox/mapbox-navigation-ios/pull/150))

## v0.2.0 (April 14, 2017)

* Renamed MapboxNavigation and MapboxNavigationUI to MapboxCoreNavigation and MapboxNavigation, respectively. MapboxNavigation provides the complete turn-by-turn navigation experience, including UI and voice announcements, while MapboxCoreNavigation provides the raw utilities for building your own UI. ([#129](https://github.com/mapbox/mapbox-navigation-ios/pull/129))
* Exposed methods on NavigationMapView that you can override to customize the route line’s appearance on the map. ([#116](https://github.com/mapbox/mapbox-navigation-ios/pull/116))
* Removed an unused dependency on MapboxGeocoder.swift. ([#112](https://github.com/mapbox/mapbox-navigation-ios/pull/112))
* Fixed memory leaks. ([#120](https://github.com/mapbox/mapbox-navigation-ios/pull/120))

## v0.1.0 (March 30, 2017)

* Adds MapboxNavigationUI for a drop in navigation experience
* Allows for Integration with [AWS Polly](https://aws.amazon.com/polly/) for improved voice announcements
* Adds optional user snapping to route line. This option also snaps the users course
* Fixes an issue where announcements with`Continue`would not announce the way names correctly
* Updates to Swift v3.1
* Fixed an issue where the route line was not inserted below labels after re-routing.

## v0.0.4 (January 24, 2017)

- Fixed an issue where a `finalHeading` just below `360` and a user heading just above `0`, would not be less than `RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion` ([#25](https://github.com/mapbox/MapboxNavigation.swift/pull/25))
- Better specified the swift version ([#26](https://github.com/mapbox/MapboxNavigation.swift/pull/26))

## v0.0.3 (January 19, 2017)

- Fixes CocoaPod installation error

## v0.0.2 (January 19, 2017)

Initial public release
