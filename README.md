# [Mapbox Navigation SDK for iOS](https://docs.mapbox.com/ios/navigation/)

[![CircleCI](https://circleci.com/gh/mapbox/mapbox-navigation-ios.svg?style=svg)](https://circleci.com/gh/mapbox/mapbox-navigation-ios)
[![codecov](https://codecov.io/gh/mapbox/mapbox-navigation-ios/branch/master/graph/badge.svg)](https://codecov.io/gh/mapbox/mapbox-navigation-ios)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/v/MapboxNavigation.svg)](https://cocoapods.org/pods/MapboxNavigation/)

<img alt="Mapbox Navigation SDK" src="./docs/img/navigation.png" width="258" align="right" />

Mapbox Navigation gives you all the tools you need to add turn-by-turn navigation to your iOS application.

Get up and running in a few minutes with our drop-in turn-by-turn navigation `NavigationViewController`, or build a completely custom turn-by-turn navigation app with our core components for routing and navigation.

## Features

* A full-fledged turn-by-turn navigation UI for iPhone, iPad, and CarPlay that’s ready to drop into your application
* [Professionally designed map styles](https://www.mapbox.com/maps/) for daytime and nighttime driving
* Worldwide driving, cycling, and walking directions powered by [open data](https://www.mapbox.com/about/open/) and user feedback
* Traffic avoidance and proactive rerouting based on current conditions in [over 55 countries](https://docs.mapbox.com/help/how-mapbox-works/directions/#traffic-data)
* Natural-sounding turn instructions powered by [Amazon Polly](https://aws.amazon.com/polly/) (no configuration needed)
* [Support for over two dozen languages](https://docs.mapbox.com/ios/navigation/overview/localization-and-internationalization/)

## [Documentation](https://docs.mapbox.com/ios/api/navigation/)

## Requirements

The Mapbox Navigation SDK and Core Navigation are compatible with applications written in Swift 5 in Xcode 11.4.1 and above. The Mapbox Navigation and Mapbox Core Navigation frameworks run on iOS 10.0 and above.

The Mapbox Navigation SDK is also available [for Android](https://github.com/mapbox/mapbox-navigation-android/).

## Installing the latest stable release

### Using CocoaPods

To install Mapbox Navigation using [CocoaPods](https://cocoapods.org/):

1. Create a [Podfile](https://guides.cocoapods.org/syntax/podfile.html) with the following specification:
   ```ruby
   pod 'MapboxNavigation', '~> 0.40.0'
   ```

1. Run `pod repo update && pod install` and open the resulting Xcode workspace.

### Using Carthage

Alternatively, to install Mapbox Navigation using [Carthage](https://github.com/Carthage/Carthage/):

1. Create a [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#github-repositories) with the following dependency:
   ```cartfile
   github "mapbox/mapbox-navigation-ios" ~> 0.40
   ```

1. Run `carthage update --platform iOS` to build just the iOS dependencies.

1. Follow the rest of [Carthage’s iOS integration instructions](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos). Your application target’s Embedded Frameworks should include `MapboxNavigation.framework`, `MapboxCoreNavigation.framework`, `MapboxNavigationNative.framework`, and `MapboxAccounts.framework`.

## Installing the latest prerelease

### Using CocoaPods

To install Mapbox Navigation using [CocoaPods](https://cocoapods.org/):

1. Create a [Bintray](https://bintray.com/mapbox) account, then [request to be added to the Mapbox Navigation SDK beta testing program](https://docs.google.com/forms/d/1mzknLZf5W9o8-KnQJ1GiYyG2grXVRqNxqHruWYTRVPc/viewform).

1. [Get a Bintray API key](https://bintray.com/profile/edit).

1. Add or append to a .netrc file in your home directory:
   ```
   machine dl.bintray.com
     login username@mapbox
     password BINTRAY_API_KEY
   ```
   where _username_ is your user name and _BINTRAY_API_KEY_ is your Bintray API key.

1. Create a [Podfile](https://guides.cocoapods.org/syntax/podfile.html) with the following specification:
   ```ruby
   pod 'MapboxCoreNavigation', :git => 'https://github.com/mapbox/mapbox-navigation-ios.git', :tag => 'v1.0.0-beta.1'
   pod 'MapboxNavigation', :git => 'https://github.com/mapbox/mapbox-navigation-ios.git', :tag => 'v1.0.0-beta.1'
   ```

1. Run `pod repo update && pod install` and open the resulting Xcode workspace.

### Using Carthage

Alternatively, to install Mapbox Navigation using [Carthage](https://github.com/Carthage/Carthage/) v0.35 or above:

1. Create a [Bintray](https://bintray.com/mapbox) account, then [request to be added to the Mapbox Navigation SDK beta testing program](https://docs.google.com/forms/d/1mzknLZf5W9o8-KnQJ1GiYyG2grXVRqNxqHruWYTRVPc/viewform).

1. [Get a Bintray API key](https://bintray.com/profile/edit).

1. Add or append to a .netrc file in your home directory:
   ```
   machine dl.bintray.com
     login username@mapbox
     password BINTRAY_API_KEY
   ```
   where _username_ is your user name and _BINTRAY_API_KEY_ is your Bintray API key.

1. _(Optional)_ Clear your Carthage caches:
   ```bash
   rm -rf ~/Library/Caches/carthage/ ~/Library/Caches/org.carthage.CarthageKit/binaries/{MapboxAccounts,MapboxNavigationNative,Mapbox-iOS-SDK}
   ```

1. Create a [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#github-repositories) with the following dependency:
   ```cartfile
   github "mapbox/mapbox-navigation-ios" "v1.0.0-beta.1"
   ```

1. Run `carthage update --platform iOS --use-netrc` to build just the iOS dependencies.

1. Follow the rest of [Carthage’s iOS integration instructions](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos). Your application target’s Embedded Frameworks should include `MapboxNavigation.framework`, `MapboxCoreNavigation.framework`, `MapboxNavigationNative.framework`, and `MapboxAccounts.framework`.

## Configuration

1. Mapbox APIs and vector tiles require a Mapbox account and API access token. In the project editor, select the application target, then go to the Info tab. Under the “Custom iOS Target Properties” section, set `MGLMapboxAccessToken` to your access token. You can obtain an access token from the [Mapbox account page](https://account.mapbox.com/access-tokens/).

1. In order for the SDK to track the user’s location as they move along the route, set `NSLocationWhenInUseUsageDescription` to:
   > Shows your location on the map and helps improve the map.

1. Users expect the SDK to continue to track the user’s location and deliver audible instructions even while a different application is visible or the device is locked. Go to the Signing & Capabilities tab. Under the Background Modes section, enable “Audio, AirPlay, and Picture in Picture” and “Location updates”. (Alternatively, add the `audio` and `location` values to the `UIBackgroundModes` array in the Info tab.)

Now import the relevant modules and present a new `NavigationViewController`. You can also [push to a navigation view controller from within a storyboard](https://docs.mapbox.com/ios/navigation/overview/storyboards/) if your application’s UI is laid out in Interface Builder.

```swift
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation
```

```swift
// Define two waypoints to travel between
let origin = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.9131752, longitude: -77.0324047), name: "Mapbox")
let destination = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.8977, longitude: -77.0365), name: "White House")

// Set options
let routeOptions = NavigationRouteOptions(waypoints: [origin, destination])

// Request a route using MapboxDirections
Directions.shared.calculate(routeOptions) { [weak self] (session, result) in
    switch result {
    case .failure(let error):
        print(error.localizedDescription)
    case .success(let response):
        guard let route = response.routes?.first, let strongSelf = self else {
            return
        }
        // Pass the generated route to the the NavigationViewController
        let viewController = NavigationViewController(for: route, routeOptions: routeOptions)
        viewController.modalPresentationStyle = .fullScreen
        strongSelf.present(viewController, animated: true, completion: nil)
    }
}
```

Consult the [API reference](https://docs.mapbox.com/ios/api/navigation/) for further details.

## Examples

The [API reference](https://docs.mapbox.com/ios/api/navigation/) includes example code for accomplishing common tasks. You can run these examples as part of the [navigation-ios-examples](https://github.com/mapbox/navigation-ios-examples) project.

This repository also contains [a testbed](https://github.com/mapbox/mapbox-navigation-ios/tree/master/Example) that exercises a variety of navigation SDK features:

1. Clone the repository or download the [.zip file](https://github.com/mapbox/mapbox-navigation-ios/archive/master.zip)
1. Run `carthage update --platform ios --use-netrc` to build just the iOS dependencies.
1. Open `MapboxNavigation.xcodeproj`.
1. Sign up or log in to your Mapbox account and grab a [Mapbox Access Token](https://account.mapbox.com/access-tokens/).
1. Open the Info.plist in the `Example` target and paste your [Mapbox Access Token](https://account.mapbox.com/access-tokens/) into `MGLMapboxAccessToken`. (Alternatively, if you plan to use this project as the basis for a public project on GitHub, place the access token in a plain text file named `.mapbox` or `mapbox` in your home directory instead of adding it to Info.plist.)
1. Build and run the `Example` target.

## Customization

### Styling

You can customize the appearance in order to blend in with the rest of your app. Checkout [`DayStyle.swift`](https://github.com/mapbox/mapbox-navigation-ios/blob/master/MapboxNavigation/DayStyle.swift) for all styleable elements.

```swift
class CustomStyle: DayStyle {
    required init() {
        super.init()
        mapStyleURL = URL(string: "mapbox://styles/mapbox/satellite-streets-v9")!
        styleType = .nightStyle
    }

    override func apply() {
        super.apply()
        BottomBannerView.appearance().backgroundColor = .orange
    }
}
```

then initialize `NavigationViewController` with your style or styles:

```swift
let navigationOptions = NavigationOptions(styles: [CustomStyle()])
NavigationViewController(for: route, routeOptions: routeOptions, navigationOptions: navigationOptions)
```

### Starting from scratch

If your application needs something totally custom, such as a voice-only experience or an unconventional user interface, consult the [Core Navigation installation guide](./custom-navigation.md).

## Contributing

We welcome feedback and code contributions! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

## License

The Mapbox Navigation SDK for iOS is released under the ISC License. See [LICENSE.md](./LICENSE.md) for details.

The Mapbox Navigation SDK for iOS depends on private binary distributions of the Mapbox Maps SDK for iOS and MapboxNavigationNative. These binaries may be used with a Mapbox account and under the [Mapbox Terms of Service](https://www.mapbox.com/tos/). If you do not wish to use these binaries, make sure you swap out these dependencies in the [Cartfile](./Cartfile#L3) or override them in your Podfile.
