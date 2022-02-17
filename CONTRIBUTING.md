# Contributing to the Mapbox Navigation SDK for iOS

## Reporting an issue

Bug reports and feature requests are more than welcome, but please consider the following tips so we can respond to your feedback more effectively.

Please familiarize yourself with the contributor license agreement (CLA) at the bottom of this document. All contributions to the project must reflect its development standards and be offered under the terms of the CLA.

Before reporting a bug here, please determine whether the issue lies with the navigation SDK itself or with another Mapbox product:

* For general questions and troubleshooting help, please contact the [Mapbox support](https://www.mapbox.com/contact/support/) team.
* Report problems with the map’s contents or routing problems, especially problems specific to a particular route or region, using the [Mapbox Feedback](https://apps.mapbox.com/feedback/) tool.
* Report problems in guidance instructions in the [OSRM Text Instructions](https://github.com/Project-OSRM/osrm-text-instructions/) repository (for Directions API profiles powered by OSRM) or the [Valhalla](https://github.com/valhalla/valhalla/) repository (for profiles powered by Valhalla).

When reporting a bug in the navigation SDK itself, please indicate:

* The version of MapboxNavigation or MapboxCoreNavigation you installed
* The version of CocoaPods, Carthage, or Swift Package Manager that you used to install the package
* The version of Xcode you used to build the package
* The iOS version and device model on which you experienced the issue
* Any relevant settings in `NavigationRouteOptions` or `NavigationMatchOptions`
* Any relevant language settings

## Setting up a development environment

To contribute code changes to this project, use Swift Package Manager to set up a development environment. The repository includes:
1. `MapboxNavigation-SPM.xcodeproj` with Example or Example-CarPlay applications. 
1. `MapboxNavigation.xcodeproj`, which builds the navigation SDK and its dependencies using Carthage but does not include a sample application.

### Using Carthage

To build this SDK, you need Xcode 12.4 and [Carthage](https://github.com/Carthage/Carthage/) v0.38:

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

1. Run `carthage bootstrap --platform iOS --cache-builds --use-xcframeworks --use-netrc`.

1. Once the Carthage build finishes, open `MapboxNavigation.xcodeproj` in Xcode and build the MapboxNavigation scheme.

1. Open the Info.plist in the `Example` target and paste your [Mapbox Access Token](https://account.mapbox.com/access-tokens/) into `MGLMapboxAccessToken`. (Alternatively, if you plan to use this project as the basis for a public project on GitHub, place the access token in a plain text file named `.mapbox` or `mapbox` in your home directory instead of adding it to Info.plist.)

1. Switch to the Example or Example-CarPlay scheme, then Run the scheme to see the SDK in action.

### Using Swift Package Manager

In Xcode, go to Source Control ‣ Clone, enter `https://github.com/mapbox/mapbox-navigation-ios.git`, and click Clone.

Alternatively, on the command line:

```bash
git clone https://github.com/mapbox/mapbox-navigation-ios.git
cd mapbox-navigation-ios/
open Package.swift
```

The resulting package only includes the framework and test targets. It does not include the example applications, and the file list is not synchronized with the Xcode project used by Carthage, so make sure to [build and test the SDK in the Xcode workspace](#using-carthage) before opening a pull request.

### Adding new files

If you add a new file while working with `Package.swift`, don't forget to add this file to `MapboxNavigation.xcodeproj` in the appropriate location.

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
* [OSRM Text Instructions](https://www.transifex.com/project-osrm/osrm-text-instructions/), which some Mapbox Directions API profiles use to generate textual and verbal turn instructions ([instructions](https://github.com/Project-OSRM/osrm-text-instructions/blob/master/CONTRIBUTING.md#adding-or-updating-a-localization))
* [Valhalla Phrases](https://www.transifex.com/valhalla/valhalla-phrases/), which some Mapbox Directions API profiles use to generate textual and verbal turn instructions ([instructions](https://github.com/valhalla/valhalla/tree/master/locales#contributing-translations))
* [Mapbox Navigation SDK for Android](https://www.transifex.com/mapbox/mapbox-navigation-sdk-for-android/), the analogous library for Android applications ([instructions](https://github.com/mapbox/mapbox-navigation-android/blob/master/CONTRIBUTING.md#adding-or-updating-a-localization))

Once you’ve finished translating the iOS navigation SDK into a new language in Transifex, open an issue in this repository asking to pull in your localization. Or do it yourself and open a pull request with the results:

1. _(First time only.)_ Download the [`tx` command line tool](https://docs.transifex.com/client/installing-the-client) and [configure your .transifexrc](https://docs.transifex.com/client/client-configuration).
1. In MapboxNavigation.xcodeproj, open the project editor. Using the project editor’s sidebar or tab bar dropdown, go to the “MapboxNavigation” project. Under the Localizations section of the Info tab, click the + button to add your language to the project.
1. In the sheet that appears, select all the files, then click Finish.

The .strings files should still be in the original English – that’s expected. Now you can pull your translations into this repository:

1. Run `tx pull -a` to fetch translations from Transifex. You can restrict the operation to just the new language using `tx pull -l xyz`, where _xyz_ is the language code.
1. To facilitate diffing and merging, convert any added .strings files from UTF-16 encoding to UTF-8 encoding. You can convert the file encoding using Xcode’s File inspector or by running `scripts/convert_string_files.sh`.
1. For each of the localizable files in the project, open the file, then, in the File inspector, check the box for your new localization.

## Adding tests

### Supported devices:
- iPhone 11 Pro Max, iOS 13.7
- iPhone 12 Pro Max, iOS 14.4
- iPhone 13 Pro Max, iOS 15.2

### Adding a unit test suite

1. Add a Unit Test Case Class file to the `MapboxCoreNavigationTests` group in `MapboxNavigation.xcodeproj`. It will be located in `Tests/MapboxCoreNavigationTests/`.
1. If a unit test requires a fixture, add a file to `Sources/TestHelper/Fixtures/`. Import `TestHelper` and call `Fixture.stringFromFileNamed(name:)` or `Fixture.JSONFromFileNamed(name:)`.

### Adding a snapshot test suite

Snapshot tests verified using [SnapshotTesting](https://github.com/pointfreeco/swift-snapshot-testing) library.

1. Open Package.swift in Xcode.
1. Select the `MapboxNavigation-Package` scheme.
1. Add a Swift file to the `Tests/MapboxNavigationTests/` folder.
1. Write an `XCTestCase` as you would normally do.
1. Make sure to apply the desired style in `XCTestCase.setup()`. For example:
   ```swift
   DayStyle().apply()
   ```
1. Use `assertImageSnapshot` function to verify views.
   ```swift
   let view: UIView
   ...
   assertImageSnapshot(matching: view, as: .image(precision: 0.95))
   ```
1. For each [supported device](#supported-devices), do the following:
   1. Select the device as the target to run tests.
   1. Perform a test run that will generate reference images for future verification. 
   1. Perform a second test run and make sure that it succeeds. 
1. Commit new tests along with generated snapshot images.

### Running unit tests

Go to Product ‣ Test in Xcode. Snapshot tests will only pass if you select iPhone 8 Plus as the target device.

## Opening a pull request

Pull requests are appreciated. If your PR includes any changes that would impact developers or end users, please mention those changes in the “main” section of [CHANGELOG.md](CHANGELOG.md), noting the PR number. Examples of noteworthy changes include new features, fixes for user-visible bugs, and renamed or deleted public symbols.

Before we can merge your PR, it must pass automated continuous integration checks in each of the supported environments, as well as a check to ensure that code coverage has not decreased significantly.

## Contributor License Agreement

Thank you for contributing to the Mapbox Navigation SDK for iOS ("the SDK")! This Contributor License Agreement (“Agreement”) sets out the terms governing any source code, object code, bug fixes, configuration changes, tools, specifications, documentation, data, materials, feedback, information or other works of authorship that you submit, beginning February 19, 2021, in any form and in any manner, to the SDK (https://github.com/mapbox/mapbox-navigation-ios) (collectively “Contributions”).

You agree that the following terms apply to all of your Contributions beginning February 19, 2021. Except for the licenses you grant under this Agreement, you retain all of your right, title and interest in and to your Contributions.

**Disclaimer.** To the fullest extent permitted under applicable law, you provide your Contributions on an "as-is" basis, without any warranties or conditions, express or implied, including, without limitation, any implied warranties or conditions of non-infringement, merchantability or fitness for a particular purpose. You have no obligation to provide support for your Contributions, but you may offer support to the extent you desire.

**Copyright License.** You hereby grant, and agree to grant, to Mapbox, Inc. (“Mapbox”) a non-exclusive, perpetual, irrevocable, worldwide, fully-paid, royalty-free, transferable copyright license to reproduce, prepare derivative works of, publicly display, publicly perform, and distribute your Contributions and such derivative works, with the right to sublicense the foregoing rights through multiple tiers of sublicensees.

**Patent License.** To the extent you have or will have patent rights to grant, you hereby grant, and agree to grant, to Mapbox a non-exclusive, perpetual, irrevocable, worldwide, fully-paid, royalty-free, transferable patent license to make, have made, use, offer to sell, sell, import, and otherwise transfer your Contributions, for any patent claims infringed by your Contributions alone or by combination of your Contributions with the SDK, with the right to sublicense these rights through multiple tiers of sublicensees.

**Moral Rights.** To the fullest extent permitted under applicable law, you hereby waive, and agree not to assert, all of your “moral rights” in or relating to your Contributions for the benefit of Mapbox, its assigns, and their respective direct and indirect sublicensees.

**Third Party Content/Rights.** If your Contribution includes or is based on any source code, object code, bug fixes, configuration changes, tools, specifications, documentation, data, materials, feedback, information, or other works of authorship that you did not author (“Third Party Content”), or if you are aware of any third party intellectual property or proprietary rights in your Contribution (“Third Party Rights”), then you agree to include with the submission of your Contribution full details on such Third Party Content and Third Party Rights, including, without limitation, identification of which aspects of your Contribution contain Third Party Content or are associated with Third Party Rights, the owner/author of the Third Party Content and/or Third Party Rights, where you obtained the Third Party Content, and any applicable third party license terms or restrictions for the Third Party Content and/or Third Party Rights. (You need not identify material from the Mapbox Web SDK project as “Third Party Content” to fulfill the obligations in this paragraph.)

**Representations.** You represent that, other than the Third Party Content and Third Party Rights you identify in your Contributions in accordance with this Agreement, you are the sole author of your Contributions and are legally entitled to grant the licenses and waivers in this Agreement. If your Contributions were created in the course of your employment with your past or present employer(s), you represent that such employer(s) has authorized you to make your Contributions on behalf of such employer(s) or such employer(s) has waived all of their right, title or interest in or to your Contributions.

**No Obligation.** You acknowledge that Mapbox is under no obligation to use or incorporate your Contributions into the SDK. Mapbox has sole discretion in deciding whether to use or incorporate your Contributions.

**Disputes.** These Terms are governed by and construed in accordance with the laws of California, without giving effect to any principles of conflicts of law. Any action arising out of or relating to these Terms must be filed in the state or federal courts for San Francisco County, California, USA, and you hereby consent and submit to the exclusive personal jurisdiction and venue of these courts for the purposes of litigating any such action.

**Assignment.** You agree that Mapbox may assign this Agreement, and all of its rights, obligations and licenses hereunder.
