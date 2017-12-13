# Supported languages

| Language | UI Elements | PollyVoiceController |
|----------|-------------|----------------------|
| Catalan | ✅ | ❌ |
| Chinese (Simplified) | ✅ | ❌ |
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

When a language is not supported by Polly, the SDK falls back to iOS's built in speech synthesizer, [AVSpeechSynthesizer](https://developer.apple.com/documentation/avfoundation/avspeechsynthesizer) which should support most languages.

# Adding or updating UI elements
