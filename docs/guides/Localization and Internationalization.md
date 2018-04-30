# Localization and Internationalization

The Mapbox Navigation SDK supports over a dozen major languages as well as some other locale settings. For a seamless user experience, the SDK’s default behavior matches the standard iOS behavior as much as possible, but several customization options are also available for specialized use cases.

## User interface

The Mapbox Navigation SDK’s user interface automatically matches your application’s language whenever possible. For the best user experience, you should localize your application fully rather than piecemeal. However, if you want to display a turn-by-turn navigation experience in a language without first localizing your application, you can add the language to your Xcode project’s languages and add a stub Localizable.strings file to your application target. For more information about preparing your application for additional languages, consult “[Localizing Your App](https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPInternational/LocalizingYourApp/LocalizingYourApp.html)” in Apple developer documentation.

Distances, travel times, and arrival times are displayed according to the system language and region settings by default, regardless of the application’s language. By default, the measurement system is that of the [spoken instructions](#spoken-instructions). To override the measurement system displayed in the user interface but not that of the spoken instructions, set the `NavigationSettings.distanceUnit` property.

The turn banner names the upcoming road or ramp destination in the local or national language. In some regions, the name may be given in multiple languages or scripts. A label near the bottom bar displays the current road name in the local language as well.

By default, the map inside `NavigationViewController` displays road labels in the local language, while points of interest and places are displayed in the system’s preferred language, if that language is one of the eight supported by the [Mapbox Streets source](https://www.mapbox.com/vector-tiles/mapbox-streets-v7/#overview). The user can set the system’s preferred
language in Settings, General Settings, Language & Region.

A standalone `NavigationMapView` labels roads, points of interest, and places in the language specified by the current style. (The default Mapbox Navigation Guidance Day v2 style specifies English.) To match the behavior of the map inside `NavigationViewController`, call the `NavigationMapView.localizeLabels()` method from within `MGLMapViewDelegate.mapView(_:didFinishLoading:)`:

```swift
func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
    if let mapView = mapView as? NavigationMapView {
        mapView.localizeLabels()
    }
}
```

## Spoken instructions

Turn instructions are announced in the user interface language when turn instructions are available in that language. Otherwise, if turn instructions are unavailable in that language, they are announced in English instead. To have instructions announced in a language other than the user interface language, set the `RouteOptions.locale` property when calculating the route with which to start navigation.

Turn instructions are primarily designed to be announced by either the Mapbox Voice API (powered by [Amazon Polly](https://docs.aws.amazon.com/polly/latest/dg/SupportedLanguage.html)) or the [Speech Synthesis framework][iossynth] built into iOS (also known as `AVSpeechSynthesizer`). This SDK uses the Mapbox Voice API by default. If the Voice API lacks support for the turn instruction language, `AVSpeechSynthesizer` announces the instructions instead. The Voice API requires an Internet connection at various points along the route. To have `AVSpeechSynthesizer` announce the instructions regardless of the language, initialize a `RouteVoiceController`, then set `NavigationViewController.voiceController` to the `RouteVoiceController` before presenting the `NavigationViewController`. Neither the Voice API nor `AVSpeechSynthesizer` supports Catalan or Vietnamese; for these languages, you must create a subclass of `RouteVoiceController` that uses a third-party speech synthesizer.

By default, distances are given in the predominant measurement system of the system region, which may not necessarily be the same region in which the user is traveling. To override the measurement system used in spoken instructions, set the `RouteOptions.distanceMeasurementSystem` property when calculating the route with which to start navigation.

The upcoming road or ramp destination is named according to the local or national language. In some regions, the name may be given in multiple languages.

## Supported languages

| Language   | User interface | [Spoken instructions][osrmti] | Mapbox Voice API | [`AVSpeechSynthesizer`][iossynth]<br>(iOS 11)
|------------|:--------------:|:-----------------------------:|:---------------------:|:--------------------------------:
| Arabic    | ✅              | —                             | —                     | ✅
| Catalan    | ✅              | —                             | —                     | —
| Chinese    | ✅ Simplified   | ✅                             | —                     | ✅
| Danish     | ✅              | ✅                             | ✅                     | ✅
| Dutch      | ✅              | ✅                             | ✅                     | ✅
| English    | ✅              | ✅                             | ✅                     | ✅
| French     | ✅              | ✅                             | ✅                     | ✅
| German     | ✅              | ✅                             | ✅                     | ✅
| Hebrew     | ✅              | ✅                             | —                     | ✅
| Hungarian  | ✅              | —                             | —                     | ✅
| Italian    | ✅              | ✅                             | ✅                     | ✅
| Korean    | ✅              | —                             | ✅                     | ✅
| Portuguese | ✅             | ✅                             | ✅                     | ✅
| Polish     | —              | ✅                             | ✅                     | ✅
| Romanian   | —              | ✅                             | ✅                     | ✅
| Russian    | ✅              | ✅                             | ✅                     | ✅
| Spanish    | ✅              | ✅                             | ✅                     | ✅
| Swedish    | ✅              | ✅                             | ✅                     | ✅
| Turkish    | —              | ✅                             | ✅                     | ✅
| Vietnamese | ✅              | ✅                             | —                     | —

## Contributing

See the [contributing guide](https://github.com/mapbox/mapbox-navigation-ios/blob/master/CONTRIBUTING.md#adding-or-updating-a-localization) for instructions on adding a new localization or improving an existing localization.

[osrmti]: https://github.com/Project-OSRM/osrm-text-instructions/
[iossynth]: https://developer.apple.com/documentation/avfoundation/speech_synthesis
