# Setting up Mapbox Navigation in a storyboard

- Open the object library and drag in a `Storyboard Reference`.
- Pick `Navigation` from the dropdown and set bundle to `com.mapbox.MapboxNavigation` (`org.cocoapods.MapboxNavigation` if you are using CocoaPods)
- Set up a segue to the storyboard reference like you would to any other UIViewController.

<img src="img/setup_ib.png" width=340>

You also need to pass a route and optionally a directions instance to the `NavigationViewController`. To do that, override your UIViewController's `prepare(for:sender:)`:

```swift
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier ?? "" {
        case "MyNavigationSegue":
            if let controller = segue.destination as? NavigationViewController {
                controller.route = route
                controller.directions = directions
            }
        default:
            break
    }
}
```
