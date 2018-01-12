# Changes to the Mapbox Navigation SDK for iOS

## master

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
