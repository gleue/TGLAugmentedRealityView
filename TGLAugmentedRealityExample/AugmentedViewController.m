//
//  AugmentedViewController.m
//  TGLAugmentedRealityExample
//
//  Created by Tim Gleue on 09.11.15.
//  Copyright (c) 2015 Tim Gleue ( http://gleue-interactive.com )
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "AugmentedViewController.h"
#import "SearchViewController.h"

#import "TGLARView.h"
#import "TGLARImageShape.h"
#import "TGLARBillboardImageShape.h"

#import "PlaceOfInterestView.h"

#import <MapKit/MKGeometry.h>

@interface AugmentedViewController () <CLLocationManagerDelegate, TGLARViewDataSource, TGLARViewDelegate, PlaceOfInterestViewDelegate>

@property (weak, nonatomic) IBOutlet TGLARView *arView;
@property (weak, nonatomic) IBOutlet UIButton *northButton;

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) PlaceOfInterest *userLocationPOI;

@end

@implementation AugmentedViewController

#pragma mark - View lifecycle

- (void)dealloc {
    
    self.places = nil;
    self.userLocationPOI = nil;
}

- (void)viewDidLoad {

	[super viewDidLoad];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;

    self.userHeight = 1.6;
    self.userLocation = self.locationManager.location;
    
    self.northButton.enabled = self.arView.isMagenticNorthAvailable;

    // A single image shape in the X/Y plane at the user's location
    //
    PlaceOfInterest *userLocationPOI = [[PlaceOfInterest alloc] init];

    userLocationPOI.title = NSLocalizedString(@"Standort", nil);
    userLocationPOI.targetPosition = GLKVector3Make(0, 0, -2.0 * self.userHeight);
    
    TGLARImageShape *shape = [[TGLARImageShape alloc] initWithContext:self.arView.renderContext size:CGSizeMake(2, 2) image:[UIImage imageNamed:@"Compass"]];

    shape.transform = GLKMatrix4Multiply(GLKMatrix4MakeRotation(M_PI, 0, 0, 1), GLKMatrix4MakeRotation(-M_PI_2, 0, 1, 0));

    userLocationPOI.overlayShape = shape;

    self.userLocationPOI = userLocationPOI;
}

- (void)viewWillAppear:(BOOL)animated {
    
	[super viewWillAppear:animated];
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    [self updateLocationServiceAuthorizationStatus:status];

    [self createOverlaysForPlaces:self.places];
    [self.arView reloadData];

	[self.arView start];

    self.arView.interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
}

- (void)viewDidDisappear:(BOOL)animated {
    
	[super viewDidDisappear:animated];
    
	[self.arView stop];
    
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - Appearance

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskAll;
}

- (UIStatusBarStyle)preferredStatusBarStyle {

    return UIStatusBarStyleLightContent;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {

    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinator> coordinator) {

        if ([UIApplication sharedApplication].statusBarOrientation != self.arView.interfaceOrientation) {

            self.arView.interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
        }
    }];
}

- (IBAction)closeSearch:(UIStoryboardSegue *)segue {
    
    SearchViewController *controller = segue.sourceViewController;
    
    self.places = controller.foundPOIs;
}

#pragma mark - Accessors

- (void)setUserHeight:(float)userHeight {

    _userHeight = userHeight;
    
    self.userLocationPOI.overlayShape.transform = GLKMatrix4MakeTranslation(0, 0, -self.userHeight);
}

- (void)setUserLocation:(CLLocation *)userLocation {
    
    if (userLocation) {
        
        _userLocation = userLocation;
        
        [self updatePlaceOverlayPositions];
    }
}

- (void)setPlaces:(NSArray<PlaceOfInterest *> *)places {

    if (self.isViewLoaded) {
    
        [self destroyOverlaysForPlaces:self.places];
    }
    
    _places = places;

    if (self.isViewLoaded) {
        
        [self createOverlaysForPlaces:self.places];
        [self.arView reloadData];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"OpenSearch"]) {
        
        UINavigationController *navigation = segue.destinationViewController;
        SearchViewController *controller = (SearchViewController *)navigation.topViewController;
        
        controller.currentLocation = self.userLocation;
        controller.foundPOIs = self.places;
    }
}

#pragma mark - Actions

- (IBAction)toggleTrueNorth:(id)sender {

    self.arView.useTrueNorth = !self.arView.isUsingTrueNorth;
    self.northButton.selected = self.arView.isUsingTrueNorth;
}

#pragma mark - CLLocationManagerDelegate protocol

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    [self updateLocationServiceAuthorizationStatus:status];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    
    self.userLocation = locations.lastObject;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    if (error.code != kCLErrorLocationUnknown) {

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Standort kann nicht ermittelt werden", nil)
                                                                       message:error.localizedDescription
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
        
        [alert addAction:ok];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)updateLocationServiceAuthorizationStatus:(CLAuthorizationStatus)status {
    
    if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Kein Zugriff auf Standort", nil)
                                                                       message:NSLocalizedString(@"Dein Standort kann nicht angezeigt werden.\n\nGehe zu den Einstellungen, um den Zugriff zu erlauben.", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
        
        [alert addAction:ok];
        
        UIAlertAction *settings = [UIAlertAction actionWithTitle:NSLocalizedString(@"Einstellungen", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^ (UIAlertAction *action) {
                                                             
                                                             NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                             
                                                             [[UIApplication sharedApplication] openURL:url];
                                                         }];
        
        [alert addAction:settings];
        
        [self presentViewController:alert animated:YES completion:nil];
        
    } else if (status == kCLAuthorizationStatusNotDetermined) {
        
        [self.locationManager requestWhenInUseAuthorization];
        
    } else if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        
        [self.locationManager startUpdatingLocation];
    }
}

#pragma mark - TGLARViewDataSource protocol

- (NSInteger)numberOfOverlaysInARView:(TGLARView *)arview {

    // All the POIs plus the user location overlay
    return self.places.count + 1;
}

- (id<TGLAROverlay>)arView:(TGLARView *)arview overlayAtIndex:(NSInteger)index {
    
    return (index < self.places.count) ? self.places[index] : self.userLocationPOI;
}

#pragma mark - TGLARViewDelegate protocol

- (void)arView:(TGLARView *)arview didTapViewOverlay:(TGLARViewOverlay *)view {

    PlaceOfInterest *poi = (PlaceOfInterest *)view.overlay;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Callout angetippt", nil)
                                                                   message:poi.title
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                 style:UIAlertActionStyleCancel
                                               handler:nil];
    
    [alert addAction:ok];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)arView:(TGLARView *)arview didTapShapeOverlay:(TGLARShapeOverlay *)shape {
    
    PlaceOfInterest *poi = (PlaceOfInterest *)shape.overlay;
    
    if (poi != self.userLocationPOI) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Shape angetippt", nil)
                                                                       message:poi.title
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
        
        [alert addAction:ok];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (CGFloat)arViewShapeOverlayNearClippingDistance:(TGLARView *)arview {
    
    return 1.0;
}

- (CGFloat)arViewShapeOverlayFarClippingDistance:(TGLARView *)arview {
    
    return 2000.0;
}

#pragma amrk - PlaceOfInterestViewDelegate protocol

- (void)poiViewButtonTapped:(PlaceOfInterestView *)view {
    
    PlaceOfInterest *poi = (PlaceOfInterest *)view.overlay;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Info angetippt", nil)
                                                                   message:poi.title
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                 style:UIAlertActionStyleCancel
                                               handler:nil];
    
    [alert addAction:ok];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Helpers

- (void)createOverlaysForPlaces:(NSArray<PlaceOfInterest *> *)places {

    for (PlaceOfInterest *place in places) {
        
        if (!place.overlayView) {

            PlaceOfInterestView *overlayView = [[PlaceOfInterestView alloc] init];
            
            overlayView.place = place;
            overlayView.delegate = self;
            overlayView.calloutLineColor = [UIColor redColor];
            overlayView.contentView.backgroundColor = [UIColor redColor];

            place.overlayView = overlayView;
        }
        
        if (!place.overlayShape) {
            
            place.overlayShape = [[TGLARBillboardImageShape alloc] initWithContext:self.arView.renderContext size:CGSizeMake(100.0, 100.0) image:[UIImage imageNamed:@"Target"]];
        }
    }
    
    [self updatePlaceOverlayPositions];
}

- (void)updatePlaceOverlayPositions {
    
    // The overlay -targetPositions are relative to the
    // camera position, which is located at the origin.
    //
    // Therefore we compute the distances in the X and Y
    // directions and set the overlay position accordingly.
    //
    // NOTE: Since the POI altitued are always zero we
    //       do not set the Z component here.
    //
    MKMapPoint userPoint = MKMapPointForCoordinate(self.userLocation.coordinate);
    
    for (PlaceOfInterest *place in self.places) {
        
        MKMapPoint overlayPoint = MKMapPointForCoordinate(place.coordinate);
        
        MKMapPoint westPoint = MKMapPointMake(overlayPoint.x, userPoint.y);
        CLLocationDistance westDistance = MKMetersBetweenMapPoints(userPoint, westPoint);
        
        if (userPoint.x < overlayPoint.x) westDistance = -westDistance;
        
        MKMapPoint northPoint = MKMapPointMake(userPoint.x, overlayPoint.y);
        CLLocationDistance northDistance = MKMetersBetweenMapPoints(userPoint, northPoint);
        
        if (userPoint.y < overlayPoint.y) northDistance = -northDistance;
        
        GLKVector3 overlayPosition = GLKVector3Make(northDistance, westDistance, (place == self.userLocationPOI) ? -2.0 * self.userHeight : 0.0);
        
        place.targetPosition = overlayPosition;
    }
}

- (void)destroyOverlaysForPlaces:(NSArray<PlaceOfInterest *> *)places {

    for (PlaceOfInterest *place in places) {
        
        place.overlayShape = nil;
        place.overlayView = nil;
    }
}

@end
