# Supported languages

| Language | UI Elements | PollyVoiceController |
|----------|-------------|----------------------|
| Catalan | ✅ | ❌ |
| Chinese (Simplified) | ✅ | ❌ |
| Danish | ✅ | ❌ |
| Dutch | ✅ | ✅ |
| English | ✅ | ✅ |
| French | ✅ | ✅ |
| German | ✅ | ✅ |
| Hungarian | ✅ | ❌ |
| Italian | ✅ | ✅ |
| Portuguese | ✅ | ✅ |
| Polish | ❌ | ✅ |
| Romanian | ❌ | ✅ |
| Russian | ✅ | ✅ |
| Spanish | ✅ | ✅ |
| Swedish | ✅ | ✅ |
| Turkish | ❌ | ✅ |
| Vietnamese | ✅ | ❌ |

The `PollyVoiceController` is powered by Amazon Web Service's Polly product. If Polly supports a language, we will add support for it in [`PollyVoiceController`](https://github.com/mapbox/mapbox-navigation-ios/blob/1d74296aa4c6adc779193fad07f0c97de2f79e90/MapboxNavigation/PollyVoiceController.swift#L99). Reference [AWS Polly supported languages](https://docs.aws.amazon.com/polly/latest/dg/SupportedLanguage.html).

When a language is not supported by Polly, the SDK falls back to iOS's built in speech synthesizer, [AVSpeechSynthesizer](https://developer.apple.com/documentation/avfoundation/avspeechsynthesizer) which should support most languages. In this case, all languages listed [here are supported](https://www.mapbox.com/api-documentation/#instructions-languages).

This SDK automatically matches the application’s language when possible. The developer has no control over the navigation UI. To enable one of the languages above, the developer needs to localize their application into that language. Even adding stub `Localizable.strings` file will work.

Note that street and destination names – as displayed on the map and UI and heard in spoken instructions – are currently limited to the name tag in OpenStreetMap, which is generally the local or national language. In some regions, the name may include multiple languages or scripts.

# Add a new language or contribute to an existing

Interested in adding or updating a language? See [contributing guide](./CONTRIBUTING.md#adding-or-updating-a-localization).
