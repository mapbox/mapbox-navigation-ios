<h3 align="center">
  <a href="https://github.com/fastlane/fastlane/tree/master/fastlane">
    <img src="../fastlane/assets/fastlane.png" width="150" />
    <br />
    fastlane
  </a>
</h3>
<p align="center">
  <a href="https://github.com/fastlane/fastlane/tree/master/deliver">deliver</a> &bull;
  <b>snapshot</b> &bull;
  <a href="https://github.com/fastlane/fastlane/tree/master/frameit">frameit</a> &bull;
  <a href="https://github.com/fastlane/fastlane/tree/master/pem">pem</a> &bull;
  <a href="https://github.com/fastlane/fastlane/tree/master/sigh">sigh</a> &bull;
  <a href="https://github.com/fastlane/fastlane/tree/master/produce">produce</a> &bull;
  <a href="https://github.com/fastlane/fastlane/tree/master/cert">cert</a> &bull;
  <a href="https://github.com/fastlane/fastlane/tree/master/spaceship">spaceship</a> &bull;
  <a href="https://github.com/fastlane/fastlane/tree/master/pilot">pilot</a> &bull;
  <a href="https://github.com/fastlane/boarding">boarding</a> &bull;
  <a href="https://github.com/fastlane/fastlane/tree/master/gym">gym</a> &bull;
  <a href="https://github.com/fastlane/fastlane/tree/master/scan">scan</a> &bull;
  <a href="https://github.com/fastlane/fastlane/tree/master/match">match</a>
</p>
-------

<p align="center">
  <img src="assets/snapshot.png" height="110">
</p>

snapshot
============

[![Twitter: @FastlaneTools](https://img.shields.io/badge/contact-@FastlaneTools-blue.svg?style=flat)](https://twitter.com/FastlaneTools)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/fastlane/fastlane/blob/master/snapshot/LICENSE)
[![Gem](https://img.shields.io/gem/v/snapshot.svg?style=flat)](http://rubygems.org/gems/snapshot)

###### Automate taking localized screenshots of your iOS and tvOS apps on every device

<hr />
<h4 align="center">
  Check out the new <a href="https://docs.fastlane.tools/getting-started/ios/screenshots">fastlane documentation</a> on how to generate screenshots
</h4>
<hr />

_snapshot_ generates localized iOS and tvOS screenshots for different device types and languages for the App Store and can be uploaded using ([`deliver`](https://github.com/fastlane/fastlane/tree/master/deliver)).

You have to manually create 20 (languages) x 6 (devices) x 5 (screenshots) = **600 screenshots**.

It's hard to get everything right!

- New screenshots with every (design) update
- No loading indicators
- Same content / screens
- [Clean Status Bar](#use-a-clean-status-bar)
- Uploading screenshots ([`deliver`](https://github.com/fastlane/fastlane/tree/master/deliver) is your friend)

More information about [creating perfect screenshots](https://krausefx.com/blog/creating-perfect-app-store-screenshots-of-your-ios-app).

_snapshot_ runs completely in the background - you can do something else, while your computer takes the screenshots for you.

Get in contact with the developer on Twitter: [@FastlaneTools](https://twitter.com/FastlaneTools)

-------
<p align="center">
    <a href="#features">Features</a> &bull;
    <a href="#installation">Installation</a> &bull;
    <a href="#ui-tests">UI Tests</a> &bull;
    <a href="#quick-start">Quick Start</a> &bull;
    <a href="#usage">Usage</a> &bull;
    <a href="#tips">Tips</a> &bull;
    <a href="#how-does-it-work">How?</a> &bull;
    <a href="#need-help">Need help?</a>
</p>

-------

<h5 align="center"><code>snapshot</code> is part of <a href="https://fastlane.tools">fastlane</a>: The easiest way to automate beta deployments and releases for your iOS and Android apps.</h5>

# Features
- Create hundreds of screenshots in multiple languages on all simulators
- Configure it once, store the configuration in git
- Do something else, while the computer takes the screenshots for you
- Integrates with [`fastlane`](https://fastlane.tools) and [`deliver`](https://github.com/fastlane/fastlane/tree/master/deliver)
- Generates a beautiful web page, which shows all screenshots on all devices. This is perfect to send to Q&A or the marketing team
- _snapshot_ automatically waits for network requests to be finished before taking a screenshot (we don't want loading images in the App Store screenshots)

##### [Like this tool? Be the first to know about updates and new fastlane tools](https://tinyletter.com/krausefx)

After _snapshot_ successfully created new screenshots, it will generate a beautiful HTML file to get a quick overview of all screens:

![assets/htmlPagePreviewFade.jpg](assets/htmlPagePreviewFade.jpg)

## Why?

This tool automatically switches the language and device type and runs UI Tests for every combination.

### Why should I automate this process?

- It takes **hours** to take screenshots
- You get a great overview of all your screens, running on all available simulators without the need to manually start it hundreds of times
- Easy verification for translators (without an iDevice) that translations do make sense in real App context
- Easy verification that localizations fit into labels on all screen dimensions
- It is an integration test: You can test for UI elements and other things inside your scripts
- Be so nice, and provide new screenshots with every App Store update. Your customers deserve it
- You realise, there is a spelling mistake in one of the screens? Well, just correct it and re-run the script

# Installation

Install the gem

    sudo gem install snapshot

Make sure, you have the latest version of the Xcode command line tools installed:

    xcode-select --install

# UI Tests

## Getting started
This project uses Apple's newly announced UI Tests. We will not go into detail on how to write scripts.

Here a few links to get started:

- [WWDC 2015 Introduction to UI Tests](https://developer.apple.com/videos/play/wwdc2015-406/)
- [A first look into UI Tests](http://www.mokacoding.com/blog/xcode-7-ui-testing/)
- [UI Testing in Xcode 7](http://masilotti.com/ui-testing-xcode-7/)
- [HSTestingBackchannel : ‘Cheat’ by communicating directly with your app](https://github.com/ConfusedVorlon/HSTestingBackchannel)
- [Automating App Store screenshots using fastlane snapshot and frameit](https://tisunov.github.io/2015/11/06/automating-app-store-screenshots-generation-with-fastlane-snapshot-and-sketch.html)

# Quick Start

- Create a new UI Test target in your Xcode project ([top part of this article](https://krausefx.com/blog/run-xcode-7-ui-tests-from-the-command-line))
- Run `snapshot init` in your project folder
- Add the ./SnapshotHelper.swift to your UI Test target (You can move the file anywhere you want)
- (Objective C only) add the bridging header to your test class.
 - `#import "MYUITests-Swift.h"`
 - The bridging header is named after your test target with -Swift.h appended.
- In your UI Test class, click the `Record` button on the bottom left and record your interaction
- To take a snapshot, call the following between interactions
 -  Swift: `snapshot("01LoginScreen")`
 -  Objective C: `[Snapshot snapshot:@"01LoginScreen" waitForLoadingIndicator:YES];`
- Add the following code to your `setUp()` method

**Swift**
```swift
let app = XCUIApplication()
setupSnapshot(app)
app.launch()
```

**Objective C**
```objective-c
XCUIApplication *app = [[XCUIApplication alloc] init];
[Snapshot setupSnapshot:app];
[app launch];
```

![assets/snapshot.gif](assets/snapshot.gif)

You can try the _snapshot_ [example project](https://github.com/fastlane/fastlane/tree/master/snapshot/example) by cloning this repo.

To quick start your UI tests, you can use the UI Test recorder. You only have to interact with the simulator, and Xcode will generate the UI Test code for you. You can find the red record button on the bottom of the screen (more information in [this blog post](https://krausefx.com/blog/run-xcode-7-ui-tests-from-the-command-line))

# Usage

```sh
snapshot
```

Your screenshots will be stored in the `./screenshots/` folder by default (or `./fastlane/screenshots` if you're using [fastlane](https://fastlane.tools))

If any error occurs while running the snapshot script on a device, that device will not have any screenshots, and _snapshot_ will continue with the next device or language. To stop the flow after the first error, run

```sh
snapshot --stop_after_first_error
```

Also by default, _snapshot_ will open the HTML after all is done. This can be skipped with the following command


```sh
snapshot --stop_after_first_error --skip_open_summary
```

There are a lot of options available that define how to build your app, for example

```sh
snapshot --scheme "UITests" --configuration "Release"  --sdk "iphonesimulator"
```

Reinstall the app before running _snapshot_

```sh
snapshot --reinstall_app --app_identifier "tools.fastlane.app"
```

By default _snapshot_ automatically retries running UI Tests if they fail. This is due to randomly failing UI Tests (e.g. [#372](https://github.com/fastlane/snapshot/issues/372)). You can adapt this number using

```sh
snapshot --number_of_retries 3
```

Add photos and/or videos to the simulator before running _snapshot_

```sh
snapshot --add_photos MyTestApp/Assets/demo.jpg --add_videos MyTestApp/Assets/demo.mp4
```

For a list for all available options run

```sh
snapshot --help
```

After running _snapshot_ you will get a nice summary:

<img src="assets/testSummary.png" width="500">

## Snapfile

All of the available options can also be stored in a configuration file called the `Snapfile`. Since most values will not change often for your project, it is recommended to store them there:

First make sure to have a `Snapfile` (you get it for free when running `snapshot init`)

The `Snapfile` can contain all the options that are also available on `snapshot --help`


```ruby
scheme "UITests"

devices([
  "iPhone 6",
  "iPhone 6 Plus",
  "iPhone 5",
  "iPhone 4s"
])

languages([
  "en-US",
  "de-DE",
  "es-ES",
  ["pt", "pt_BR"] # Portuguese with Brazilian locale
])

launch_arguments(["-username Felix"])

# The directory in which the screenshots should be stored
output_directory './screenshots'

clear_previous_screenshots true

add_photos ["MyTestApp/Assets/demo.jpg"]

```

### Completely reset all simulators

You can run this command in the terminal to delete and re-create all iOS and tvOS simulators:

```
snapshot reset_simulators
```

**Warning**: This will delete **all** your simulators and replace by new ones! This is useful, if you run into weird problems when running _snapshot_.

You can use the environment variable `SNAPSHOT_FORCE_DELETE` to stop asking for confirmation before deleting.

## Update snapshot helpers

Some updates require the helper files to be updated. _snapshot_ will automatically warn you and tell you how to update.

Basically you can run

```
snapshot update
```

to update your `SnapshotHelper.swift` files. In case you modified your `SnapshotHelper.swift` and want to manually update the file, check out [SnapshotHelper.swift](https://github.com/fastlane/fastlane/blob/master/snapshot/lib/assets/SnapshotHelper.swift).

## Launch Arguments

You can provide additional arguments to your app on launch. These strings will be available in your app (eg. not in the testing target) through `NSProcessInfo.processInfo().arguments`. Alternatively, use user-default syntax (`-key value`) and they will be available as key-value pairs in `NSUserDefaults.standardUserDefaults()`.

```ruby
launch_arguments([
  "-firstName Felix -lastName Krause"
])
```

```swift
name.text = NSUserDefaults.standardUserDefaults().stringForKey("firstName")
// name.text = "Felix"
```

_snapshot_ includes `-FASTLANE_SNAPSHOT YES`, which will set a temporary user default for the key `FASTLANE_SNAPSHOT`, you may use this to detect when the app is run by _snapshot_.

```swift
if NSUserDefaults.standardUserDefaults().boolForKey("FASTLANE_SNAPSHOT") {
    // runtime check that we are in snapshot mode
}
```

Specify multiple argument strings and _snapshot_ will generate screenshots for each combination of arguments, devices, and languages. This is useful for comparing the same screenshots with different feature flags, dynamic text sizes, and different data sets.

```ruby
# Snapfile for A/B Test Comparison
launch_arguments([
  "-secretFeatureEnabled YES",
  "-secretFeatureEnabled NO"
])
```

# How does it work?

The easiest solution would be to just render the UIWindow into a file. That's not possible because UI Tests don't run on a main thread. So _snapshot_ uses a different approach:

When you run unit tests in Xcode, the reporter generates a plist file, documenting all events that occurred during the tests ([More Information](http://michele.io/test-logs-in-xcode)). Additionally, Xcode generates screenshots before, during and after each of these events. There is no way to manually trigger a screenshot event. The screenshots and the plist files are stored in the DerivedData directory, which _snapshot_ stores in a temporary folder.

When the user calls `snapshot(...)` in the UI Tests (Swift or Objective C) the script actually does a rotation to `.Unknown` which doesn't have any effect on the actual app, but is enough to trigger a screenshot. It has no effect to the application and is not something you would do in your tests. The goal was to find *some* event that a user would never trigger, so that we know it's from _snapshot_. On tvOS, there is no orientation so we ask for a count of app views with type "Browser" (which should never exist on tvOS).

_snapshot_ then iterates through all test events and check where we either did this weird rotation (on iOS) or searched for browsers (on tvOS). Once _snapshot_ has all events triggered by _snapshot_ it collects a ordered list of all the file names of the actual screenshots of the application.

In the test output, the Swift _snapshot_ function will print out something like this

> snapshot: [some random text here]

_snapshot_ finds all these entries using a regex. The number of _snapshot_ outputs in the terminal and the number of _snapshot_ events in the plist file should be the same. Knowing that, _snapshot_ automatically matches these 2 lists to identify the name of each of these screenshots. They are then copied over to the output directory and separated by language and device.

2 thing have to be passed on from _snapshot_ to the `xcodebuild` command line tool:

- The device type is passed via the `destination` parameter of the `xcodebuild` parameter
- The language is passed via a temporary file which is written by _snapshot_ before running the tests and read by the UI Tests when launching the application

If you find a better way to do any of this, please submit an issue on GitHub or even a pull request :+1:

Also, feel free to duplicate radar [23062925](https://openradar.appspot.com/radar?id=5056366381105152).

# Tips

<hr />
<h4 align="center">
  Check out the new <a href="https://docs.fastlane.tools/getting-started/ios/screenshots">fastlane documentation</a> on how to generate screenshots
</h4>
<hr />

## [`fastlane`](https://fastlane.tools) Toolchain

- [`fastlane`](https://fastlane.tools): The easiest way to automate beta deployments and releases for your iOS and Android apps
- [`deliver`](https://github.com/fastlane/fastlane/tree/master/deliver): Upload screenshots, metadata and your app to the App Store
- [`frameit`](https://github.com/fastlane/fastlane/tree/master/frameit): Quickly put your screenshots into the right device frames
- [`PEM`](https://github.com/fastlane/fastlane/tree/master/pem): Automatically generate and renew your push notification profiles
- [`sigh`](https://github.com/fastlane/fastlane/tree/master/sigh): Because you would rather spend your time building stuff than fighting provisioning
- [`produce`](https://github.com/fastlane/fastlane/tree/master/produce): Create new iOS apps on iTunes Connect and Dev Portal using the command line
- [`cert`](https://github.com/fastlane/fastlane/tree/master/cert): Automatically create and maintain iOS code signing certificates
- [`spaceship`](https://github.com/fastlane/fastlane/tree/master/spaceship): Ruby library to access the Apple Dev Center and iTunes Connect
- [`pilot`](https://github.com/fastlane/fastlane/tree/master/pilot): The best way to manage your TestFlight testers and builds from your terminal
- [`boarding`](https://github.com/fastlane/boarding): The easiest way to invite your TestFlight beta testers
- [`gym`](https://github.com/fastlane/fastlane/tree/master/gym): Building your iOS apps has never been easier
- [`scan`](https://github.com/fastlane/fastlane/tree/master/scan): The easiest way to run tests of your iOS and Mac app
- [`match`](https://github.com/fastlane/fastlane/tree/master/match): Easily sync your certificates and profiles across your team using git

##### [Like this tool? Be the first to know about updates and new fastlane tools](https://tinyletter.com/krausefx)

## Frame the screenshots

If you want to add frames around the screenshots and even put a title on top, check out [frameit](https://github.com/fastlane/fastlane/tree/master/frameit).

## Available language codes
```ruby
ALL_LANGUAGES = ["da", "de-DE", "el", "en-AU", "en-CA", "en-GB", "en-US", "es-ES", "es-MX", "fi", "fr-CA", "fr-FR", "id", "it", "ja", "ko", "ms", "nl", "no", "pt-BR", "pt-PT", "ru", "sv", "th", "tr", "vi", "zh-Hans", "zh-Hant"]
```

To get more information about language and locale codes please read [Internationalization and Localization Guide](https://developer.apple.com/library/ios/documentation/MacOSX/Conceptual/BPInternational/LanguageandLocaleIDs/LanguageandLocaleIDs.html).

## Use a clean status bar
You can use [SimulatorStatusMagic](https://github.com/shinydevelopment/SimulatorStatusMagic) to clean up the status bar.

## Editing the `Snapfile`
Change syntax highlighting to *Ruby*.

### Simulator doesn't launch the application

When the app dies directly after the application is launched there might be 2 problems

- The simulator is somehow in a broken state and you need to re-create it. You can use `snapshot reset_simulators` to reset all simulators (this will remove all installed apps)
- A restart helps very often

## Determine language

To detect the currently used localization in your tests, access the `deviceLanguage` variable from `SnapshotHelper.swift`.

# Need help?
Please submit an issue on GitHub and provide information about your setup

# Code of Conduct
Help us keep _snapshot_ open and inclusive. Please read and follow our [Code of Conduct](https://github.com/fastlane/fastlane/blob/master/CODE_OF_CONDUCT.md).

# License
This project is licensed under the terms of the MIT license. See the LICENSE file.

> This project and all fastlane tools are in no way affiliated with Apple Inc. This project is open source under the MIT license, which means you have full access to the source code and can modify it to fit your own needs. All fastlane tools run on your own computer or server, so your credentials or other sensitive information will never leave your own computer. You are responsible for how you use fastlane tools.
