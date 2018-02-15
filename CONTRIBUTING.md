# Contributing to the Mapbox Navigation SDK for iOS

## Reporting an issue

Bug reports and feature requests are more than welcome, but please consider the following tips so we can respond to your feedback more effectively.

Before reporting a bug here, please determine whether the issue lies with the navigation SDK itself or with another Mapbox product:

* For general questions and troubleshooting help, please contact the [Mapbox support](https://www.mapbox.com/contact/support/) team.
* Report problems with the map’s contents using the [Mapbox Feedback](https://www.mapbox.com/map-feedback/) tool.
* Report routing problems, especially problems specific to a particular route or region, using the [Mapbox Directions Feedback](https://www.mapbox.com/directions-feedback/) tool.
* Report problems in guidance instructions in the [OSRM Text Instructions](https://github.com/Project-OSRM/osrm-text-instructions/) repository.

When reporting a bug in the navigation SDK itself, please indicate:

* The navigation SDK version
* Whether you installed the SDK using CocoaPods or Carthage
* The iOS version, iPhone model, and Xcode version, as applicable
* Any relevant language settings

## Building the SDK

To build this SDK, you need Xcode 9 and [Carthage](https://github.com/Carthage/Carthage/):

1. Run `carthage bootstrap --platform iOS --cache-builds`.
1. Once the Carthage build finishes, open `MapboxNavigation.xcodeproj` in Xcode and build the MapboxNavigation scheme.

See [the README](./README.md#running-the-example-project) for instructions on building and running the included Swift and Objective-C example projects.

## Opening a pull request

Pull requests are appreciated. If your PR includes any changes that would impact developers or end users, please mention those changes in the “master” section of [CHANGELOG.md](CHANGELOG.md), noting the PR number. Examples of noteworthy changes include new features, fixes for user-visible bugs, renamed or deleted public symbols, and changes that affect bridging to Objective-C.

## Making any symbol public

To add any type, constant, or member to the SDK’s public interface:

1. Ensure that the symbol bridges to Objective-C and does not rely on any language features specific to Swift – so no namespaced types or classes named with emoji! 🙃
1. Name the symbol according to [Swift design guidelines](https://swift.org/documentation/api-design-guidelines/) and [Cocoa naming conventions](https://developer.apple.com/library/prerelease/content/documentation/Cocoa/Conceptual/CodingGuidelines/CodingGuidelines.html#//apple_ref/doc/uid/10000146i).
1. Use `@objc(…)` to specify an Objective-C-specific name that conforms to Objective-C naming conventions. Use the `MB` class prefix to avoid conflicts with client code.
1. Provide full documentation comments. We use [jazzy](https://github.com/realm/jazzy/) to produce the documentation found [on the website for this SDK](http://mapbox.com/mapbox-navigation-ios/navigation/). Many developers also rely on Xcode’s Quick Help feature, which supports a subset of Markdown.
1. _(Optional.)_ Add the type or constant’s name to the relevant category in the `custom_categories` section of [the jazzy configuration file](./docs/jazzy.yml). This is required for classes and protocols and also recommended for any other type that is strongly associated with a particular class or protocol. If you leave out this step, the symbol will appear in an “Other” section in the generated HTML documentation’s table of contents.

## Adding image assets

Image assets are designed in a [PaintCode](http://paintcodeapp.com/) document managed in the [navigation-ui-resources](https://github.com/mapbox/navigation-ui-resources/) repository. After changes to that repository are merged, export the PaintCode drawings as Swift source code and add or replace files in the [MapboxNavigation](https://github.com/mapbox/mapbox-navigation-ios/tree/master/MapboxNavigation/) folder.

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

The Mapbox Navigation SDK for iOS features several translations contributed through [Transifex](https://www.transifex.com/mapbox/mapbox-navigation-ios/). If your language already has a translation, feel free to complete or proofread it. Otherwise, please [request your language](https://www.transifex.com/mapbox/mapbox-navigation-ios/). Note that we’re primarily interested in languages that iOS supports as system languages.

While you’re there, consider also translating the [Mapbox Maps SDK for iOS](https://www.transifex.com/mapbox/mapbox-gl-native/), which the navigation SDK depends on, and [OSRM Text Instructions](https://www.transifex.com/project-osrm/osrm-text-instructions/), which builds a list of textual and verbal instructions along the route. You can also help translate the [Mapbox Navigation SDK for Android](https://www.transifex.com/mapbox/mapbox-navigation-sdk-for-android/).

Once you’ve finished translating the navigation SDK into a new language in Transifex, perform these steps to make Xcode aware of the translation:

1. _(First time only.)_ Download the [`tx` command line tool](https://docs.transifex.com/client/installing-the-client) and [configure your .transifexrc](https://docs.transifex.com/client/client-configuration).
1. In MapboxNavigation.xcodeproj, open the project editor. Using the project editor’s sidebar or tab bar dropdown, go to the “MapboxNavigation” project. Under the Localizations section of the Info tab, click the + button to add your language to the project.
1. In the sheet that appears, select all the files, then click Finish.

The .strings files should still be in the original English – that’s expected. Now you can pull your translations into this repository:

1. Run `tx pull -a` to fetch translations from Transifex. You can restrict the operation to just the new language using `tx pull -l xyz`, where _xyz_ is the language code.
1. To facilitate diffing and merging, convert any added .strings files from UTF-16 encoding to UTF-8 encoding. You can convert the file encoding using Xcode’s File inspector or by running `scripts/convert_string_files.sh`.
1. If you’ve translated the “localizableabbreviations” resource, change to the [scripts/abbreviations/](scripts/abbreviations/) folder and run `./main import xyz`, where _xyz_ is the language code.
1. For each of the localizable files in the project, open the file, then, in the File inspector, check the box for your new localization.
1. Add the new language to [the language support matrix](languages.md).
