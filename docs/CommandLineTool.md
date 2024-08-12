#  Mapbox Directions Command Line Tool

## Getting Started
`mapbox-directions-swift` is a command line tool, designed to round-trip an arbitrary, JSON-formatted Directions or Map Matching API response through model objects and back to JSON. This is useful for various scenarios including testing purposes and designing more sophisticated API response processing pipelines. It is supplied as a Swift package.

To build `MapboxDirectionsCLI` using SPM:

1. `swift build --target "MapboxDirectionsCLI"`

To run (and build if it wasn't yet) `MapboxDirectionsCLI` and see usage:

1. `swift run mapbox-directions-swift -h`

To run the `MapboxDirectionsCLI` within Xcode, select the `MapboxDirectionsCLI` target and edit the scheme to include arguments passed at launch.

## Configuration

A [Mapbox access token](https://docs.mapbox.com/help/glossary/access-token/) is required for some operations. Set the `MAPBOX_ACCESS_TOKEN` environment variable to your access token.

To connect to an API endpoint other than the default Mapbox API endpoint, set the `MAPBOX_HOST` environment variable to the base URL.

## Usage and Recipes

`mapbox-directions-swift` is a useful tool for mobile quality assurance. This tool can be used to verify a response to ensure proper Directions API integration, get a [GPX](https://wikipedia.org/wiki/GPS_Exchange_Format) trace that can be used in the Xcode Simulator, and convert a Directions API request to an Options object.

### Arguments

The sole argument is either:

* The path to a JSON file that contains a serialized `NavigationRouteOptions` or `NavigationMatchOptions`
* The URL of a Mapbox Directions API or Mapbox Map Matching API request

### Options
`--input`
An optional flag for the filepath to the input JSON. If this flag is not used, `mapbox-directions-swift` will fallback to a Directions API request.

`--output`
An optional flag for the filepath to save the conversion result. If no filepath is provided, the result will output to the shell. If you want a GPX trace that can be easily uploaded to Xcode, provide an output filepath with this flag.

`--format`
An optional flag for the output format. `mapbox-directions-swift` supports text, json, and gpx formats. If you want to simulate a route within the Xcode simulator, you will need a GPX trace. This tool can return a route response as in Xcode-compatible GPX format by using the following recipe: To get a GPX trace that can be used in the Xcode simulator, you can use the following recipe:
```
swift run mapbox-directions-swift route -c < PATH TO CONFIG FILE (with your RouteOptions JSON) > \
-f gpx \
-i < PATH TO INPUT FILE (with your Directions API response) > \
-o < PATH TO OUTPUT FILE >
```

`--url`
If you want an alternative to the JSON input file, you can provide a Directions API request URL string to the command line tool. For example,
```
swift run mapbox-directions-swift route -c < PATH TO CONFIG FILE (with your RouteOptions JSON) > \
-f text \
-i < PATH TO INPUT FILE (with your Directions API response) > \
-u < URL REQUEST STRING >
```


