# Contributing to the Mapbox Navigation SDK for iOS

## Reporting an issue

Bug reports and feature requests are more than welcome, but please consider the following tips so we can respond to your feedback more effectively.

Before reporting a bug here, please determine whether the issue lies with the navigation SDK itself or with another Mapbox product:

* For general questions and troubleshooting help, please contact the [Mapbox support](https://www.mapbox.com/contact/support/) team.
* Report problems with the map’s contents or routing problems, especially problems specific to a particular route or region, using the [Mapbox Feedback](https://apps.mapbox.com/feedback/) tool.
* Report problems in guidance instructions in the [OSRM Text Instructions](https://github.com/Project-OSRM/osrm-text-instructions/) repository.

When reporting a bug in the navigation SDK itself, please indicate:

* The navigation SDK version
* Whether you installed the SDK using CocoaPods or Carthage
* The iOS version, iPhone model, and Xcode version, as applicable
* Any relevant language settings

## Building the SDK

To build this SDK, you need Xcode 11.4.1 and [Carthage](https://github.com/Carthage/Carthage/) v0.35:

1. Go to your [Mapbox account dashboard](https://account.mapbox.com/) and create an access token that has the `DOWNLOADS:READ` scope. **PLEASE NOTE: This is not the same as your production Mapbox API token. Make sure to keep it private and do not insert it into any Info.plist file.** Create a file named `.netrc` in your home directory if it doesn’t already exist, then add the following lines to the end of the file:
   ```
   machine api.mapbox.com
     login mapbox
     password PRIVATE_MAPBOX_API_TOKEN
   ```
   where _PRIVATE_MAPBOX_API_TOKEN_ is your Mapbox API token with the `DOWNLOADS:READ` scope.

1. _(Optional)_ Clear your Carthage caches:
   ```bash
   rm -rf ~/Library/Caches/carthage/ ~/Library/Caches/org.carthage.CarthageKit/binaries/{MapboxAccounts,MapboxCommon-ios,MapboxNavigationNative,mapbox-ios-sdk-dynamic}
   ```

1. Run `carthage bootstrap --platform iOS --cache-builds --use-netrc`.

1. Once the Carthage build finishes, open `MapboxNavigation.xcodeproj` in Xcode and build the MapboxNavigation scheme. Switch to the Example or Example-CarPlay scheme to see the SDK in action.

## Testing the SDK

It is important to test the SDK using the `iPhone 8 Plus` simulator for the `FBSnapshotter` tests.

## Opening a pull request

Pull requests are appreciated. If your PR includes any changes that would impact developers or end users, please mention those changes in the “main” section of [CHANGELOG.md](CHANGELOG.md), noting the PR number. Examples of noteworthy changes include new features, fixes for user-visible bugs, and renamed or deleted public symbols.

## Making any symbol public

To add any type, constant, or member to the SDK’s public interface:

1. Name the symbol according to [Swift design guidelines](https://swift.org/documentation/api-design-guidelines/) and [Cocoa naming conventions](https://developer.apple.com/library/prerelease/content/documentation/Cocoa/Conceptual/CodingGuidelines/CodingGuidelines.html#//apple_ref/doc/uid/10000146i).
1. In rare cases where a symbol needs to bridge to Objective-C to interoperate with the Objective-C runtime, use `@objc(…)` to specify an Objective-C-specific name that conforms to Objective-C naming conventions. Use the `MB` class prefix to avoid conflicts with client code.
1. Provide full documentation comments. We use [jazzy](https://github.com/realm/jazzy/) to produce the documentation found [on the website for this SDK](https://docs.mapbox.com/ios/api/navigation/). Many developers also rely on Xcode’s Quick Help feature, which supports a subset of Markdown.
1. _(Optional.)_ Add the type or constant’s name to the relevant category in the `custom_categories` section of [the jazzy configuration file](./docs/jazzy.yml). This is required for classes and protocols and also recommended for any other type that is strongly associated with a particular class or protocol. If you leave out this step, the symbol will appear in an “Other” section in the generated HTML documentation’s table of contents.

## Adding image assets

Image assets are designed in a [PaintCode](http://paintcodeapp.com/) document managed in the [navigation-ui-resources](https://github.com/mapbox/navigation-ui-resources/) repository. After changes to that repository are merged, export the PaintCode drawings as Swift source code and add or replace files in the [MapboxNavigation](https://github.com/mapbox/mapbox-navigation-ios/tree/main/MapboxNavigation/) folder.

## Adding user-facing text

To add or update text that the user may see in the navigation SDK:

1. Use the `NSLocalizedString(_:tableName:bundle:value:comment:)` method:
   ```swift
   NSLocalizedString("UNIQUE_IDENTIFIER", bundle: .mapboxNavigation, value: "What English speakers see", comment: "Where this text appears or how it is used")
   ```
1. _(Optional.)_ If you need to embed some text in a string, use `NSLocalizedString(_:tableName:bundle:value:comment:)` with `String.localizedStringWithFormat(_:_:)` instead of `String(format:)`:
   ```swift
   String.localizedStringWithFormat(NSLocalizedString("UNIQUE_IDENTIFIER", bundle: .mapboxNavigation, value: "What English speakers see with %@ for each embedded string", comment: "Format string for a string with an embedded string; 1 = the first embedded string"), embeddedString)
   ```
1. _(Optional.)_ When dealing with a number followed by a pluralized word, do not split the string. Instead, use a format string and make `val` ambiguous, like `%d file(s)`. Then pluralize for English in the appropriate [.stringsdict file](https://developer.apple.com/library/ios/documentation/MacOSX/Conceptual/BPInternational/StringsdictFileFormat/StringsdictFileFormat.html). See [MapboxNavigation/Resources/en.lproj/Localizable.stringsdict](MapboxNavigation/Resources/en.lproj/Localizable.stringsdict) for an example. Localizers should do likewise for their languages.
1. Run `scripts/extract_localizable.sh` to add the new text to the .strings files.
1. Open a pull request with your changes. Once the pull request is merged, Transifex will pick up the changes within a few hours.

## Adding or updating a localization

The Mapbox Navigation SDK for iOS features several translations contributed through [Transifex](https://www.transifex.com/mapbox/mapbox-navigation-ios/). If your language already has a translation, feel free to complete or proofread it. Otherwise, please [request your language](https://www.transifex.com/mapbox/mapbox-navigation-ios/) so you can start translating. Note that we’re primarily interested in languages that iOS supports as system languages.

While you’re there, please consider also translating the following related projects:

* [Mapbox Maps SDK for iOS](https://www.transifex.com/mapbox/mapbox-gl-native/), which is responsible for the map view and minor UI elements such as the compass ([instructions](https://github.com/mapbox/mapbox-gl-native-ios/blob/master/platform/ios/DEVELOPING.md#adding-a-localization))
* [OSRM Text Instructions](https://www.transifex.com/project-osrm/osrm-text-instructions/), which the Mapbox Directions API uses to generate textual and verbal turn instructions ([instructions](https://github.com/Project-OSRM/osrm-text-instructions/blob/master/CONTRIBUTING.md#adding-or-updating-a-localization))
* [Mapbox Navigation SDK for Android](https://www.transifex.com/mapbox/mapbox-navigation-sdk-for-android/), the analogous library for Android applications ([instructions](https://github.com/mapbox/mapbox-navigation-android/blob/master/CONTRIBUTING.md#adding-or-updating-a-localization))

Once you’ve finished translating the iOS navigation SDK into a new language in Transifex, open an issue in this repository asking to pull in your localization. Or do it yourself and open a pull request with the results:

1. _(First time only.)_ Download the [`tx` command line tool](https://docs.transifex.com/client/installing-the-client) and [configure your .transifexrc](https://docs.transifex.com/client/client-configuration).
1. In MapboxNavigation.xcodeproj, open the project editor. Using the project editor’s sidebar or tab bar dropdown, go to the “MapboxNavigation” project. Under the Localizations section of the Info tab, click the + button to add your language to the project.
1. In the sheet that appears, select all the files, then click Finish.

The .strings files should still be in the original English – that’s expected. Now you can pull your translations into this repository:

1. Run `tx pull -a` to fetch translations from Transifex. You can restrict the operation to just the new language using `tx pull -l xyz`, where _xyz_ is the language code.
1. To facilitate diffing and merging, convert any added .strings files from UTF-16 encoding to UTF-8 encoding. You can convert the file encoding using Xcode’s File inspector or by running `scripts/convert_string_files.sh`.
1. For each of the localizable files in the project, open the file, then, in the File inspector, check the box for your new localization.
