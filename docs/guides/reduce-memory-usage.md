# Reducing memory usage

Because of the nature of a navigation app, resource consumption on a device is going to be high. This is because:

* The app is usually in the foreground for an extended period of time.
* On every location update, the map needs to update and render any necessary updates to the map.

The Navigation SDK tries to compensate and try to be as energy conscious as possible. For example, when the device is unplugged we update the map at lower frame rate then when the device is plugged in.


# What else can the developer do?

A common pattern of apps that use this SDK will show some sort of preview map view showing where the route will go. Then the user hits GO and the `NavigationViewController` is presented. However, the preview map is longer necessary to keep around in memory. An exmaple of removing this map view from the current view can be accomplished by:

```swift
present(navigationViewController, animated: true) {
    self.mapView?.removeFromSuperview()
    self.mapView = nil
}
```

Note, it then necessary to add the preview map view back to the preview screen when the user exits navigation:


```swift
// Called when the user hits the exit button.
// If implemented, you are responsible for also dismissing the UI.

func navigationViewControllerDidCancelNavigation(_ navigationViewController: NavigationViewController) {
    setupMapView()
    navigationViewController.dismiss(animated: true, completion: nil)
}
```

Following these instructions should free up somewhere on the order of 100mb.
