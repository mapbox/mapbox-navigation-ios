# Road Cameras Example — Prerequisites

Before building and running the **Road Cameras** example in AdditionalExamples:

## Mapbox account feature flags

Request these flags on your Mapbox account:

1. **`directions_api_road_cameras`** — enables the Directions API to include road camera annotations on the route (`road_camera` attribute / `RouteLeg.roadCameras`).
2. **`navigation_sdks_private_beta`** — enables Swift Package Manager to resolve the `mapbox-navigation-cpp-ios` dependency and the `MapboxNavigationCppRoadCameras` product.

## Local beta flag file

Create an empty marker file in your home directory so `Package.swift` enables beta targets:

```bash
touch ~/.mapbox-navigation-ios.navigation_sdks_private_beta
```

After creating the file, reset package caches in Xcode (File → Packages → Reset Package Caches).

## Run the example

1. Open `Examples/Examples.xcodeproj`
2. Select the **AdditionalExamples** scheme
3. Choose **Road Cameras** from the examples list
