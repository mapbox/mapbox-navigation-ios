# Reducing memory usage

Because of the nature of a navigation app, resource consumption on a device is going to be high. This is because:

* The app is usually in the foreground for an extended period of time.
* On every location update, the map needs to update and render any necessary updates to the map.

The Navigation SDK tries to compensate and be as energy conscious as possible. For example, when the device is unplugged we update the map at lower frame rate than when the device is plugged in.


# What else can the developer do?

Apps that use this SDK often begin by showing a preview map view where the route will go. Then, the user initiates navigation and the `NavigationViewController` is presented. However, the preview map is longer necessary to keep around in memory. 

UIKit will remove `NavigationMapView` from the view hierarchy when using `UIModalPresentationStyle.fullScreen`, but if you choose to use another presentation style, you can remove the preview map view from the current view using `UIView.removeFromSuperview()`:

```swift
present(navigationViewController, animated: true) {
    self.mapView?.removeFromSuperview()
    self.mapView = nil
}
```

Note, it's necessary to then add the preview map view back to the screen when the user exits navigation:


```swift
// Called when the user hits the exit button.
// If implemented, you are responsible for also dismissing the UI.

func navigationViewControllerDidCancelNavigation(_ navigationViewController: NavigationViewController) {
    setupMapView()
    navigationViewController.dismiss(animated: true, completion: nil)
}
```

Following these instructions should free up around 100MB.
