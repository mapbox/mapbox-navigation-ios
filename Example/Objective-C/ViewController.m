#import "ViewController.h"

@import AVFoundation;
@import MapboxNavigation;
@import MapboxDirections;
@import Mapbox;

@interface ViewController ()
@property (nonatomic, weak) IBOutlet MGLMapView *mapView;
@property (nonatomic, assign) CLLocationCoordinate2D destination;
@property (nonatomic) MBDirections *directions;
@property (nonatomic) MBRouteController *navigation;
@property (nonatomic) NSLengthFormatter *lengthFormatter;
@property (nonatomic) AVSpeechSynthesizer *speechSynth;
@end

@implementation ViewController

static NSString *MBXTempAlertDidChange = @"RouteControllerAlertLevelDidChange";
static NSString *MBXTempProgressDidChange = @"RouteControllerProgressDidChange";
static NSString *MBXTempShouldReRoute = @"RouteControllerShouldReroute";
static NSString *MBXTempProfileIdentifierAutomobileAvoidingTraffic = @"mapbox/driving-traffic";
static NSString *MBXTempRouteControllerAlertLevelDidChangeNotificationRouteProgressKey = @"progress";

static NSString *MapboxAccessToken = @"Your Mapbox access token";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [MGLAccountManager setAccessToken:MapboxAccessToken];
    self.directions = [[MBDirections alloc] initWithAccessToken:MapboxAccessToken];
    
    [self.mapView setStyleURL:[MGLStyle streetsStyleURLWithVersion:8]];
    self.mapView.userTrackingMode = MGLUserTrackingModeFollow;
    
    self.lengthFormatter = [[NSLengthFormatter alloc] init];
    self.lengthFormatter.unitStyle = NSFormattingUnitStyleShort;
    
    [self resumeNotifications];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self suspendNotifications];
    [self.navigation suspend];
}

- (IBAction)didLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    CGPoint point = [sender locationInView:self.mapView];
    self.destination = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    [self getRoute];
}

- (void)resumeNotifications {
    // TODO: Bridge notification names to Objective-C
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alertLevelDidChange:) name:MBXTempAlertDidChange object:_navigation];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(progressDidChange:) name:MBXTempProgressDidChange object:_navigation];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rerouted:) name:MBXTempShouldReRoute object:_navigation];
}

- (void)suspendNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MBXTempAlertDidChange object:_navigation];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MBXTempProgressDidChange object:_navigation];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MBXTempShouldReRoute object:_navigation];
}

- (void)alertLevelDidChange:(NSNotification *)notification {
    MBRouteProgress *routeProgress = (MBRouteProgress *)notification.userInfo[MBXTempRouteControllerAlertLevelDidChangeNotificationRouteProgressKey];
    // TODO: Bridge MBAlertProgress to Objective-C
}

- (void)progressDidChange:(NSNotification *)notification {
    MBRouteProgress *routeProgress = (MBRouteProgress *)notification.userInfo[MBXTempRouteControllerAlertLevelDidChangeNotificationRouteProgressKey];
    MBRouteStep *upcomingStep = routeProgress.currentLegProgress.upComingStep;
    if (upcomingStep) {
        NSLog(@"In %@ %@", [self.lengthFormatter stringFromMeters:routeProgress.currentLegProgress.currentStepProgress.distanceRemaining],
              upcomingStep.instructions);
    }
}

- (void)rerouted:(NSNotification *)notification {
    [self getRoute];
}

- (void)getRoute {
    NSArray<MBWaypoint *> *waypoints = @[[[MBWaypoint alloc] initWithCoordinate:self.mapView.userLocation.coordinate coordinateAccuracy:-1 name:nil],
                                         [[MBWaypoint alloc] initWithCoordinate:self.destination coordinateAccuracy:-1 name:nil]];
    
    MBRouteOptions *options = [[MBRouteOptions alloc] initWithWaypoints:waypoints profileIdentifier:MBXTempProfileIdentifierAutomobileAvoidingTraffic];
    options.includesSteps = YES;
    options.routeShapeResolution = MBRouteShapeResolutionFull;
    
    [self.directions calculateDirectionsWithOptions:options completionHandler:^(NSArray<MBWaypoint *> * _Nullable waypoints, NSArray<MBRoute *> * _Nullable routes, NSError * _Nullable error) {
        if (!routes.firstObject) {
            return;
        }
        
        if (self.mapView.annotations) {
            [self.mapView removeAnnotations:self.mapView.annotations];
        }
        
        MBRoute *route = routes.firstObject;
        CLLocationCoordinate2D *routeCoordinates = malloc(route.coordinateCount * sizeof(CLLocationCoordinate2D));
        [route getCoordinates:routeCoordinates];
        
        MGLPolyline *polyline = [MGLPolyline polylineWithCoordinates:routeCoordinates count:route.coordinateCount];
        
        [self.mapView addAnnotation:polyline];
        [self.mapView setVisibleCoordinates:routeCoordinates count:route.coordinateCount edgePadding:UIEdgeInsetsZero animated:YES];
        
        free(routeCoordinates);
        
        [self startNavigation:route];
    }];
}

- (void)startNavigation:(MBRoute *)route {
    self.mapView.userTrackingMode = MGLUserTrackingModeFollowWithCourse;
    self.navigation = [[MBRouteController alloc] initWithRoute:route];
    [self.navigation resume];
}

@end
