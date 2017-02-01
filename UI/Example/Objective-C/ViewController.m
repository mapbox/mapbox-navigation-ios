#import "ViewController.h"

@import AVFoundation;
@import MapboxNavigation;
@import MapboxNavigationUI;
@import MapboxDirections;
@import Mapbox;

@interface ViewController () <AVSpeechSynthesizerDelegate>
@property (nonatomic, weak) IBOutlet MGLMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *instructionsView;
@property (weak, nonatomic) IBOutlet UILabel *instructionsLabel;
@property (nonatomic, assign) CLLocationCoordinate2D destination;
@property (nonatomic) MBDirections *directions;
@property (nonatomic) MBRouteController *navigation;
@property (nonatomic) NSLengthFormatter *lengthFormatter;
@property (nonatomic) AVSpeechSynthesizer *speechSynth;
@end

@implementation ViewController

static NSString *MBXTempProfileIdentifierAutomobileAvoidingTraffic = @"mapbox/driving-traffic";
static NSString *MapboxAccessToken = @"<#Your Mapbox access token#>";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [MGLAccountManager setAccessToken:MapboxAccessToken];
    self.directions = [[MBDirections alloc] initWithAccessToken:MapboxAccessToken];
    
    [self.mapView setStyleURL:[MGLStyle streetsStyleURLWithVersion:8]];
    self.mapView.userTrackingMode = MGLUserTrackingModeFollow;
    
    self.lengthFormatter = [[NSLengthFormatter alloc] init];
    self.lengthFormatter.unitStyle = NSFormattingUnitStyleShort;
    
    self.speechSynth = [[AVSpeechSynthesizer alloc] init];
    self.speechSynth.delegate = self;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alertLevelDidChange:) name:MBRouteControllerAlertLevelDidChange object:_navigation];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(progressDidChange:) name:MBRouteControllerNotificationProgressDidChange object:_navigation];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rerouted:) name:MBRouteControllerShouldReroute object:_navigation];
}

- (void)suspendNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MBRouteControllerAlertLevelDidChange object:_navigation];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MBRouteControllerNotificationProgressDidChange object:_navigation];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MBRouteControllerShouldReroute object:_navigation];
}

- (void)alertLevelDidChange:(NSNotification *)notification {
    MBRouteProgress *routeProgress = (MBRouteProgress *)notification.userInfo[MBRouteControllerNotificationProgressDidChange];
    MBRouteStep *upcomingStep = routeProgress.currentLegProgress.upComingStep;
    
    NSString *text = nil;
    if (upcomingStep) {
        MBAlertLevel alertLevel = routeProgress.currentLegProgress.alertUserLevel;
        if (alertLevel == MBAlertLevelHigh) {
            text = upcomingStep.instructions;
        } else {
            text = [NSString stringWithFormat:@"In %@ %@",
                    [self.lengthFormatter stringFromMeters:routeProgress.currentLegProgress.currentStepProgress.distanceRemaining],
                    upcomingStep.instructions];
        }
    } else {
        text = [NSString stringWithFormat:@"In %@ %@",
                [self.lengthFormatter stringFromMeters:routeProgress.currentLegProgress.currentStepProgress.distanceRemaining],
                routeProgress.currentLegProgress.currentStep.instructions];
    }
    
    [self.speechSynth speakUtterance:[AVSpeechUtterance speechUtteranceWithString:text]];
}

- (void)progressDidChange:(NSNotification *)notification {
    MBRouteProgress *routeProgress = (MBRouteProgress *)notification.userInfo[MBRouteControllerAlertLevelDidChangeNotificationRouteProgressKey];
    MBRouteStep *upcomingStep = routeProgress.currentLegProgress.upComingStep;
    if (upcomingStep) {
        self.instructionsView.hidden = NO;
        self.instructionsLabel.text = [NSString stringWithFormat:@"In %@ %@",
                                       [self.lengthFormatter stringFromMeters:routeProgress.currentLegProgress.currentStepProgress.distanceRemaining],
                                       upcomingStep.instructions];
    } else {
        self.instructionsView.hidden = YES;
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
    
    NSURLSessionDataTask *task = [self.directions calculateDirectionsWithOptions:options completionHandler:^(NSArray<MBWaypoint *> * _Nullable waypoints, NSArray<MBRoute *> * _Nullable routes, NSError * _Nullable error) {
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
    
    [task resume];
}

- (void)startNavigation:(MBRoute *)route {
    self.mapView.userTrackingMode = MGLUserTrackingModeFollowWithCourse;
    self.navigation = [[MBRouteController alloc] initWithRoute:route];
    [self.navigation resume];
}

@end
