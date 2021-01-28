#pragma once

#include <math.h>

#import <CoreLocation/CoreLocation.h>
#import <CoreGraphics/CoreGraphics.h>

static const double tileSize = 512;
static const double DEG2RAD = M_PI / 180.0;
static const double M2PI = M_PI * 2;
static const double EARTH_RADIUS_M = 6378137;
static const double LATITUDE_MAX = 85.051128779806604;
static const double MIN_ZOOM = 0.0;
static const double MAX_ZOOM = 25.5;

static const CLLocationDegrees AngularFieldOfView = 30;

static double clamp(double value, double min_, double max_) {
    return fmax(min_, fmin(max_, value));
}

static double worldSize(double scale) {
    return scale * tileSize;
}

static CGFloat RadiansFromDegrees(CLLocationDegrees degrees) {
    return (CGFloat)(degrees * M_PI) / 180;
}

static double getMetersPerPixelAtLatitude(double lat, double zoom) {
    const double constrainedZoom = clamp(zoom, MIN_ZOOM, MAX_ZOOM);
    const double constrainedScale = pow(2.0, constrainedZoom);
    const double constrainedLatitude = clamp(lat, -LATITUDE_MAX, LATITUDE_MAX);
    return cos(constrainedLatitude * DEG2RAD) * M2PI * EARTH_RADIUS_M / worldSize(constrainedScale);
}

static CLLocationDistance AltitudeForZoomLevel(double zoomLevel, CGFloat pitch, CLLocationDegrees latitude, CGSize size) {
    CLLocationDistance metersPerPixel = getMetersPerPixelAtLatitude(latitude, zoomLevel);
    CLLocationDistance metersTall = metersPerPixel * size.height;
    CLLocationDistance altitude = metersTall / 2 / tan(RadiansFromDegrees(AngularFieldOfView) / 2.);
    return altitude * sin(M_PI_2 - RadiansFromDegrees(pitch)) / sin(M_PI_2);
}

static double ZoomLevelForAltitude(CLLocationDistance altitude, CGFloat pitch, CLLocationDegrees latitude, CGSize size) {
    CLLocationDistance eyeAltitude = altitude / sin(M_PI_2 - RadiansFromDegrees(pitch)) * sin(M_PI_2);
    CLLocationDistance metersTall = eyeAltitude * 2 * tan(RadiansFromDegrees(AngularFieldOfView) / 2.);
    CLLocationDistance metersPerPixel = metersTall / size.height;
    CGFloat mapPixelWidthAtZoom = cos(RadiansFromDegrees(latitude)) * M2PI * EARTH_RADIUS_M / metersPerPixel;
    return log2(mapPixelWidthAtZoom / tileSize);
}
