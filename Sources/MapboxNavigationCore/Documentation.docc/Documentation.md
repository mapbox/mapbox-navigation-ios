# ``MapboxNavigationCore``

The Navigation Core framework provides the basic components for the custom navigation experience.

## Overview

The Navigation SDK for iOS allows you to build a custom navigation experience with the power of the [Mapbox Directions API](https://docs.mapbox.com/api/navigation/directions/), [Mapbox Map Matching](https://docs.mapbox.com/api/navigation/map-matching/), and [Mapbox Maps](https://docs.mapbox.com/ios/maps/guides/).

## Contents

1. [Navigator](#navigator)
1. [Session](#session)
1. [Models](#models)
1. [Location](#location)
1. [Events](#events)
1. [Navigation Map](#navigation-map)
1. [Navigation Camera](#navigation-camera)
1. [Speech](#speech)
1. [Configuration](#configuration)
1. [History](#history)
1. [Copilot](#copilot)
1. [Electronic Horizon](#electronic-horizon)
1. [Feedback](#feedback)
1. [Telemetry](#telemetry)
1. [Predictive Cache](#predictive-cache)
1. [Other](#other)

## Topics

### Navigator

- ``MapboxNavigationProvider``
- ``MapboxNavigation``
- ``NavigationController``
- ``RoutingProvider``
- ``RoutingProviderSource``
- ``MapboxRoutingProvider``
- ``FasterRouteProvider``

### Session

- ``SessionController``
- ``Session``

### Models

- ``NavigationRouteOptions``
- ``NavigationMatchOptions``

- ``NavigatorError``
- ``NavigatorErrors``
- ``ReroutingError``
- ``NavigationRoutesError``

- ``NavigationRoutes``
- ``RouteId``
- ``NavigationRoute``
- ``AlternativeRoute``
- ``RouteProgress``
- ``RouteLegProgress``
- ``RouteStepProgress``

- ``RoadMatching``
- ``BorderCrossing``
- ``EtaDistanceInfo``
- ``SpeedLimit``
- ``Tunnel``
- ``Waypoint``
- ``RouteLeg``
- ``RouteStep``
- ``ProfileIdentifier``

- ``RoadInfo``
- ``SpokenInstruction``
- ``VisualInstructionBanner``

- ``CongestionLevel``
- ``RoadClasses``
- ``DirectionsError``
- ``CongestionRange``
- ``UnitOfMeasurement``

### Location

- ``LocationClient``
- ``LocationSource``
- ``MultiplexLocationClient``
- ``NavigationLocationManager``
- ``LocationSource``

### Events

- ``NavigationEvent``
- ``AlternativesEvent``
- ``AlternativesStatus``
- ``EHorizonEvent``
- ``EHorizonStatus``
- ``FasterRoutesEvent``
- ``FasterRoutesStatus``
- ``FallbackToTilesState``
- ``MapMatchingResult``
- ``MapMatchingState``
- ``RefreshingEvent``
- ``RefreshingStatus``
- ``ReroutingEvent``
- ``ReroutingStatus``
- ``RouteProgressState``
- ``SpokenInstructionState``
- ``VisualInstructionState``
- ``VoiceInstructionEvent``
- ``VoiceInstructionEvents``
- ``WaypointArrivalEvent``
- ``WaypointArrivalStatus``

### Navigation Map

- ``NavigationMapView``
- ``NavigationMapViewDelegate``

- ``RouteAnnotationKind``
- ``RoutesPresentationStyle``
- ``MapPoint``
- ``CongestionConfiguration``
- ``CongestionColorsConfiguration``
- ``CongestionRangesConfiguration``
- ``RouteLineWidthByZoomLevel``

### Navigation Camera

- ``NavigationCamera``
- ``NavigationCameraState``
- ``NavigationCameraType``
- ``CameraStateTransition``
- ``NavigationCameraStateTransition``
- ``NavigationCameraOptions``
- ``OverviewCameraOptions``
- ``FollowingCameraOptions``
- ``ViewportDataSource``
- ``ViewportState``
- ``MobileViewportDataSource``
- ``CarPlayViewportDataSource``
- ``NavigationViewportDataSourceOptions``

- ``BearingSmoothing``
- ``PitchNearManeuver``
- ``IntersectionDensity``
- ``GeometryFramingAfterManeuver``

### Speech

- ``RouteVoiceController``
- ``SpeechSynthesizing``
- ``MapboxSpeechSynthesizer``
- ``MultiplexedSpeechSynthesizer``
- ``SpeechOptions``
- ``SpeechError``
- ``SpeechFailureAction``
- ``SpeechGender``
- ``AudioFormat``
- ``TextType``
- ``VolumeMode``

### Configuration

- ``CoreConfig``
- ``ApiConfiguration``
- ``AlternativeRoutesDetectionConfig``
- ``FasterRouteDetectionConfig``
- ``IncidentsConfig``
- ``NavigationCoreApiConfiguration``
- ``RoutingConfig``
- ``PredictiveCacheConfig``
- ``RerouteConfig``
- ``StatusUpdatingSettings``
- ``TileStoreConfiguration``
- ``TTSConfig``
- ``ApprovalMode``
- ``ApprovalModeAsync``

### History

- ``History``
- ``HistoryRecording``
- ``HistoryReader``
- ``HistoryRecordingConfig``
- ``HistoryEvent``
- ``NavigationHistoryEvent``
- ``UserPushedHistoryEvent``
- ``RouteAssignmentHistoryEvent``
- ``LocationUpdateHistoryEvent``
- ``UnknownHistoryEvent``
- ``HistoryReplayController``
- ``HistoryReplayDelegate``

### Copilot

- ``CopilotService``
- ``MapboxCopilot``
- ``MapboxCopilotDelegate``
- ``NavigationSession``
- ``CopilotError``

- ``NavigationHistoryFormat``
- ``NavigationHistoryEvents``
- ``NavigationHistoryProviderError``
- ``NavigationHistoryProviderProtocol``

### Electronic Horizon

- ``ElectronicHorizonConfig``
- ``ElectronicHorizonController``

- ``RoadGraph``
- ``RoadObjectAhead``
- ``RoadObject``
- ``RoadObjectMatcher``
- ``RoadObjectMatcherDelegate``
- ``RoadObjectMatcherError``
- ``RoadObjectStore``
- ``RoadObjectStoreDelegate``

- ``DistancedRoadObject``
- ``Interchange``
- ``Junction``
- ``LocalizedRoadObjectName``
- ``OpenLRIdentifier``
- ``OpenLROrientation``
- ``OpenLRSideOfRoad``
- ``DistancedRoadObject``
- ``RoadName``
- ``LocalizedRoadObjectName``
- ``DistancedRoadObject``
- ``RoadShield``
- ``RouteAlert``

### Feedback

- ``FeedbackType``
- ``PassiveNavigationFeedbackType``
- ``ActiveNavigationFeedbackType``
- ``FeedbackEvent``
- ``FeedbackSource``
- ``FeedbackMetadata``
- ``FeedbackScreenshotOption``
- ``UserFeedback``

### Telemetry

- ``NavigationEventsManager``
- ``TelemetryAppMetadata``

### Predictive Cache

- ``PredictiveCacheManager``
- ``PredictiveCacheConfig``
- ``PredictiveCacheLocationConfig``
- ``PredictiveCacheNavigationConfig``
- ``PredictiveCacheMapsConfig``

### Other

- ``UnimplementedLogging``
- ``IdleTimerManager``
- ``EquatableClosure``
- ``SdkInfo``
- ``SkuTokenProvider``
