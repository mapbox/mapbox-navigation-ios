# Languages

## User interface

The Mapbox Navigation SDK’s user interface automatically matches your application’s language whenever possible. For the best user experience, you should localize your application fully rather than piecemeal. However, if you want to display a turn-by-turn navigation experience in a language without first localizing your application, you can add the language to your Xcode project’s languages and add a stub Localizable.strings file to your application target. For more information about preparing your application for additional languages, consult “[Localizing Your App](https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPInternational/LocalizingYourApp/LocalizingYourApp.html)” in Apple developer documentation.

Distances, travel times, and arrival times are displayed according to the system language and region settings by default, regardless of the application’s language. By default, the measurement system also matches the system region, which may not necessarily be the same region in which the user is traveling.

The turn banner names the upcoming road or ramp destination in the local or national language. In some regions, the name may be given in multiple languages or scripts.

By default, the map displays the Mapbox Navigation Guidance Day v2 and Navigation Guidance Night v2 styles, which labels roads in English wherever possible, falling back to the local language. A label near the bottom bar displays the current road name in the same language as the map. To force the labels into any of the eight other languages supported by the [Mapbox Streets source](https://www.mapbox.com/vector-tiles/mapbox-streets-v7/#overview), falling back to the local language, use the following code:

```swift
navigationViewController.mapView?.style?.localizesLabels = true
```

## Spoken instructions

Turn instructions are announced in the user interface language when turn instructions are available in that language. Otherwise, if turn instructions are unavailable in that language, they are announced in English instead. To have instructions announced in a language other than the user interface language, set the `RouteOptions.locale` property when calculating the route with which to start navigation.

Turn instructions are primarily designed to be announced by either [Amazon Polly][polly] or the [Speech Synthesis framework][iossynth] built into iOS (also known as `AVSpeechSynthesizer`). `AVSpeechSynthesizer` is used by default. To have Polly announce the instructions, initialize a `PollyVoiceController` using your AWS pool ID, then set `NavigationViewController.voiceController` to the `PollyVoiceController` before presenting the `NavigationViewController`. If Polly lacks support for the turn instruction language, `AVSpeechSynthesizer` announces the instructions instead. Neither Polly nor `AVSpeechSynthesizer` supports Catalan or Vietnamese; for these languages, you must create a subclass of `RouteVoiceController` that uses a third-party speech synthesizer.

By default, distances are given in the predominant measurement system of the system region, which may not necessarily be the same region in which the user is traveling. To override the measurement system used in spoken instructions, set the `RouteOptions.measurementSystem` property when calculating the route with which to start navigation.

The upcoming road or ramp destination is named according to the local or national language. In some regions, the name may be given in multiple languages.

## Supported languages

| Language   | User interface | [Spoken instructions][osrmti] | [Amazon Polly][polly] | [`AVSpeechSynthesizer`][iossynth]<br>(iOS 11)
|------------|----------------|-------------------------------|-----------------------|----------------------------------
| Catalan    | ✅              | ❌                             | ❌                     | ❌
| Chinese    | ✅ Simplified   | ✅                             | ❌                     | ✅
| Danish     | ✅              | ✅                             | ❌                     | ✅
| Dutch      | ✅              | ✅                             | ✅                     | ✅
| English    | ✅              | ✅                             | ✅                     | ✅
| French     | ✅              | ✅                             | ✅                     | ✅
| German     | ✅              | ✅                             | ✅                     | ✅
| Hebrew     | ✅              | ✅                             | ❌                     | ✅
| Hungarian  | ✅              | ❌                             | ❌                     | ✅
| Italian    | ✅              | ✅                             | ✅                     | ✅
| Portuguese | ✅              | ✅                             | ✅                     | ✅
| Polish     | ❌              | ✅                             | ✅                     | ✅
| Romanian   | ❌              | ✅                             | ✅                     | ✅
| Russian    | ✅              | ✅                             | ✅                     | ✅
| Spanish    | ✅              | ✅                             | ✅                     | ✅
| Swedish    | ✅              | ✅                             | ✅                     | ✅
| Turkish    | ❌              | ✅                             | ✅                     | ✅
| Vietnamese | ✅              | ✅                             | ❌                     | ❌

## Contributing

See the [contributing guide](./CONTRIBUTING.md#adding-or-updating-a-localization) for instructions on adding a new localization or improving an existing localization.

[osrmti]: https://github.com/Project-OSRM/osrm-text-instructions/
[polly]: https://docs.aws.amazon.com/polly/latest/dg/SupportedLanguage.html
[iossynth]: https://developer.apple.com/documentation/avfoundation/speech_synthesis
