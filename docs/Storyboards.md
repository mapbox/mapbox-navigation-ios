# Setting up Mapbox Navigation UI in a storyboard

- Open the object library and drag in a `Storyboard Reference`.
- Pick `Navigation` from the dropdown and set bundle to `com.mapbox.MapboxNavigationUI`.
- Set up a segue to the storyboard reference like you would to any other UIViewController.

<img src="https://cloud.githubusercontent.com/assets/764476/23622518/e3cc8a86-0253-11e7-80ab-7d34302a5fe5.png" width=340>

You also need to pass a route and optionally a directions instance to the `RouteViewController`. To do that, override your UIViewController's `prepare(for:sender:)`:

```swift
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier ?? "" {
        case "MyNavigationSegue":
            if let controller = segue.destination as? RouteViewController {
                controller.route = route
                controller.directions = directions
            }
        default:
            break
    }
}
```
