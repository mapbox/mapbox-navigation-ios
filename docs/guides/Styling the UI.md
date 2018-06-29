# Styling the UI

If you're using [`NavigationMapViewController`](https://www.mapbox.com/mapbox-navigation-ios/navigation/0.18.1/Classes/NavigationViewController.html), it's possible to apply custom fonts and colors to various parts of the UI.

### Create a new Style class

Simply subclass `DayStyle`, and make the necessary changes.

```swift
class CustomDayStyle: DayStyle {
    
    required init() {
        super.init()

        // Use a custom map style.
        mapStyleURL = URL(string: "mapbox://styles/mapbox/satellite-streets-v9")!

        // Specify that the style should be used during the day.
        styleType = .day
    }
    
    override func apply() {
        super.apply()

        // Begin styling the UI
        BottomBannerView.appearance().backgroundColor = .orange
    }
}
```

You can even provide a custom night style that will be used at night and while the user is in tunnels.

```swift
class CustomNightStyle: NightStyle {

    required init() {
        super.init()

        // Specify that the style should be used at night.
        styleType = .night
    }

    override func apply() {
        super.apply()

        // Begin styling the UI
        BottomBannerView.appearance().backgroundColor = .purple
    }
}
```

### Initialize `NavigationMapViewController` with these styles

```swift
let navigation = NavigationViewController(for: route, directions: Directions, styles: [CustomDayStyle(), CustomNightStyle()], locationManager: nil)
```

### Finding elements to style

The easiest way to find elements and their class name to style is to use the Debug View Hierarchy.

![](https://user-images.githubusercontent.com/1058624/42105575-a401f4b6-7b85-11e8-822c-d95cf88b084c.png)


1. While running your app, selecte the Debug View Hierarchy button.
2. Select the view you wish to style.
3. On the right side of your screen, not the class name.
4. Apply your styling:

```swift
DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).unitTextColor = .red
```

It is also helpful to view the default styling applied by the [`DayStyle`](https://github.com/mapbox/mapbox-navigation-ios/blob/master/MapboxNavigation/DayStyle.swift) class.