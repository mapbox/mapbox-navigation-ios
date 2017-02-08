# MapboxNavigationUI.swift

[![](https://www.bitrise.io/app/6fc45a7e2817b859.svg?token=XTgNMVxObhd8w8EmsAgJ1Q)](https://www.bitrise.io/app/6fc45a7e2817b859#/builds)

MapboxNavigationUI.swift makes it easy to get started with turn by turn navigation.
It relies heavily on [Mapbox iOS SDK](https://github.com/mapbox/mapbox-gl-native/tree/master/platform/ios), [MapboxNavigation.swift](https://github.com/mapbox/MapboxNavigation.swift), [MapboxDirections.swift](https://github.com/mapbox/MapboxDirections.swift) and [MapboxGeocoder.swift](https://github.com/mapbox/MapboxGeocoder.swift).

|![](https://cloud.githubusercontent.com/assets/764476/22738709/c23dc02e-ee08-11e6-98ff-e003a06dbe87.png) | ![](https://cloud.githubusercontent.com/assets/764476/22749696/8937b2fa-ee2e-11e6-8bf6-6ea593269b9e.png) |
| --- | --- |

### Examples
We provide examples in Swift and Objective-C. Run `pod install` from the Example folder and open `Example.xcworkspace` to try it out.

**Instantiating a navigation UI (RouteViewController)**

```swift
let controller = NavigationUI.instantiate(route: route, directions: directions)
present(controller, animated: true, completion: nil)
```

- `route` the initial route you want to navigate.
- `directions` a [Direction](https://github.com/mapbox/MapboxDirections.swift) instance needed for re-routing when the user goes off route.

**Basic styling**

![screenshot 2017-02-08 18 24 38](https://cloud.githubusercontent.com/assets/764476/22748895/e2a5fdc2-ee2b-11e6-8d1c-1cbe2fed18ad.png)

## Installation options

#### [CocoaPods](https://cocoapods.org/)

You'll need to install three pods, `MapboxNavigationUI.swift`, `MapboxNavigation.swift`  and `MapboxDirections.swift`

Add the following lines to your Podfile:

```ruby
pod 'MapboxDirections.swift', :git => 'https://github.com/mapbox/MapboxDirections.swift.git', :commit => 'ceaf58b780fc17ea44a9150041b602d017c1e567'
pod 'MapboxNavigation.swift', :git => 'https://github.com/mapbox/MapboxNavigation.swift.git', :tag => 'v0.0.4'
pod 'MapboxNavigationUI.swift', :git => 'https://github.com/mapbox/MapboxNavigation.swift.git', :tag => 'v0.0.4'
```
