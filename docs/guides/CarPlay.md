# Getting started with CarPlay

### Prerequisites

1. Xcode 10
1. An iOS 12 capable app and device
1. CarPlay entitlements from Apple. See https://developer.apple.com/contact/carplay/ for more information
1. Optional- a CarPlay enabled center console. We use [this model](https://www.amazon.com/Sony-XAV-AX100-Android-Receiver-Bluetooth/dp/B01MF9W0GU/) at Mapbox along with [this power supply for debugging](https://www.amazon.com/Pyramid-Bench-Supply-Converter-PS8KX/dp/B000A896GG/).


### How a CarPlay app is designed

![](https://user-images.githubusercontent.com/1058624/42144565-8719505a-7d70-11e8-98e0-b37e39e417ae.png)

Items visible on the CarPlay system can be devided into two categories: UI elements provided by the CarPlay framework and your navigation view containing your custom map. Anything in your navigation view, including but not limited to buttons, list views, map views, etc, do not react to touches from the user. Only UI elements provided by the CarPlay framework will by default respond to user interactions.

`CPMapTemplate` is the main entry into designing your CarPlay interface.  In your `AppDelegate` file, it's required to inherit from `CPApplicationDelegate` and implement `func application(UIApplication, didConnectCarInterfaceController: CPInterfaceController, to: CPMapContentWindow)` to connect to your CarPlay window. In this delegate method, you can create your default `CPMapTemplate` that may add a few buttons, like search or toggle panning mode.

Beyond `CPMaptemplate`, there are a handful of [other templates](https://developer.apple.com/documentation/carplay/templates) you can add to your app:
* `CPGridTemplate`
* `CPListTemplate`
* `CPSearchTemplate`
* `CPVoiceControlTemplate`

It is not possible to subclass `CPTemplate` and to design your own custom template.
