#import "ViewController.h"

@import AVFoundation;
@import MapboxCoreNavigation;
@import MapboxDirections;
@import MapboxNavigation;
@import Mapbox;

@interface ViewController () <AVSpeechSynthesizerDelegate>
@property (nonatomic, weak) IBOutlet MGLMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *toggleNavigationButton;
@property (weak, nonatomic) IBOutlet UILabel *howToBeginLabel;
@property (nonatomic, assign) CLLocationCoordinate2D destination;
@property (nonatomic) MBDirections *directions;
@property (nonatomic) MBRoute *route;
@property (nonatomic) MBRouteController *navigation;
@property (nonatomic) NSLengthFormatter *lengthFormatter;
@property (nonatomic) AVSpeechSynthesizer *speechSynth;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
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
    [self.navigation suspendLocationUpdates];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPassSpokenInstructionPoint:) name:MBRouteControllerDidPassSpokenInstructionPointNotification object:_navigation];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(progressDidChange:) name:MBRouteControllerProgressDidChangeNotification object:_navigation];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willReroute:) name:MBRouteControllerWillRerouteNotification object:_navigation];
}

- (void)suspendNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MBRouteControllerDidPassSpokenInstructionPointNotification object:_navigation];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MBRouteControllerProgressDidChangeNotification object:_navigation];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MBRouteControllerWillRerouteNotification object:_navigation];
}

- (void)didPassSpokenInstructionPoint:(NSNotification *)notification {
    MBRouteProgress *routeProgress = (MBRouteProgress *)notification.userInfo[MBRouteControllerRouteProgressKey];
    NSString *text = routeProgress.currentLegProgress.currentStepProgress.currentSpokenInstruction.text;
    
    [self.speechSynth speakUtterance:[AVSpeechUtterance speechUtteranceWithString:text]];
}

- (void)progressDidChange:(NSNotification *)notification {
    // If you are using MapboxCoreNavigation,
    // this would be a good time to update UI elements.
    // You can grab the current routeProgress like:
    // let routeProgress = notification.userInfo![RouteControllerRouteProgressKey] as! RouteProgress
}

- (void)willReroute:(NSNotification *)notification {
    [self getRoute];
}

- (void)getRoute {
    NSArray<MBWaypoint *> *waypoints = @[[[MBWaypoint alloc] initWithCoordinate:self.mapView.userLocation.coordinate coordinateAccuracy:-1 name:nil],
                                         [[MBWaypoint alloc] initWithCoordinate:self.destination coordinateAccuracy:-1 name:nil]];
    
    MBNavigationRouteOptions *options = [[MBNavigationRouteOptions alloc] initWithWaypoints:waypoints profileIdentifier:MBDirectionsProfileIdentifierAutomobileAvoidingTraffic];
    options.includesSteps = YES;
    options.routeShapeResolution = MBRouteShapeResolutionFull;
    
    NSURLSessionDataTask *task = [[MBDirections sharedDirections] calculateDirectionsWithOptions:options completionHandler:^(NSArray<MBWaypoint *> * _Nullable waypoints, NSArray<MBRoute *> * _Nullable routes, NSError * _Nullable error) {
        
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
        
        self.route = route;
        
        [self startNavigation:route];
    }];
    
    [task resume];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"StartNavigation"]) {
        MBNavigationViewController *controller = (MBNavigationViewController *)[segue destinationViewController];
        
        controller.directions = [MBDirections sharedDirections];
        controller.route = self.route;
        
        controller.routeController.locationManager = [[MBSimulatedLocationManager alloc] initWithRoute:self.route];
    }
}

- (void)startNavigation:(MBRoute *)route {
    MBSimulatedLocationManager *locationManager = [[MBSimulatedLocationManager alloc] initWithRoute:route];
    MBNavigationViewController *controller = [[MBNavigationViewController alloc] initWithRoute:route
                                                                                    directions:[MBDirections sharedDirections]
                                                                                         style:nil
                                                                               locationManager:locationManager];
    [self presentViewController:controller animated:YES completion:nil];
    
    // Suspend notifications and let `MBNavigationViewController` handle all progress and voice updates.
    [self suspendNotifications];
}

@end
