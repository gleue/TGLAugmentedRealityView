//
//  SearchViewController.m
//  TGLAugmentedRealityExample
//
//  Created by Tim Gleue on 06.11.15.
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

#import "SearchViewController.h"

#import <MapKit/MapKit.h>

static inline UIViewAnimationOptions animationOptionsWithCurve(UIViewAnimationCurve curve) {

    // See: http://stackoverflow.com/a/20188994
    //
    UIViewAnimationOptions opt = (UIViewAnimationOptions)curve;
    return opt << 16;
}

@interface SearchViewController () <MKMapViewDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBarBottomLayoutConstraint;

@property (nonatomic, readonly) MKDistanceFormatter *distanceFormatter;

@end

@implementation SearchViewController

@synthesize distanceFormatter = _distanceFormatter;

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];

    self.mapView.showsUserLocation = YES;
    self.mapView.userTrackingMode = MKUserTrackingModeNone;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self.searchBar becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];
    
    [self.mapView addAnnotations:self.foundPOIs];
}

#pragma mark - Accessors

- (void)setCurrentLocation:(CLLocation *)currentLocation {

    _currentLocation = currentLocation;
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(currentLocation.coordinate, 2000.0, 2000.0);
    
    [self.mapView setRegion:region animated:YES];
}

- (MKDistanceFormatter *)distanceFormatter {

    if (_distanceFormatter == nil) {
    
        _distanceFormatter = [[MKDistanceFormatter alloc] init];
    }
    
    return _distanceFormatter;
}

#pragma mark - MKMapViewDelegate protocol

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    if (![annotation isKindOfClass:MKUserLocation.class]) {
    
        static NSString * const ident = @"MapAnnotation";
        
        MKAnnotationView *view = [mapView dequeueReusableAnnotationViewWithIdentifier:ident];
        
        if (!view) {
            
            view = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:ident];
            
            view.image = [UIImage imageNamed:@"Pin"];
            view.centerOffset = CGPointMake(0.0, -0.5 * view.image.size.height);
            view.canShowCallout = YES;
            view.calloutOffset = CGPointMake(0.0, -0.1 * view.image.size.height);
            
            view.leftCalloutAccessoryView = [[UIImageView alloc] initWithImage:view.image];
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];

            view.rightCalloutAccessoryView = button;
            
            UILabel *detailLabel = [[UILabel alloc] init];
            
            detailLabel.font = [UIFont systemFontOfSize:10.0];
            detailLabel.textColor = [UIColor lightGrayColor];
    
            view.detailCalloutAccessoryView = detailLabel;

        } else {
            
            view.annotation = annotation;
        }
        
        if ([annotation isKindOfClass:PlaceOfInterest.class]) {
            
            UILabel *detailLabel = (UILabel *)view.detailCalloutAccessoryView;
            PlaceOfInterest *poi = (PlaceOfInterest *)annotation;

            CLLocationDistance dist = [poi.placemark.location distanceFromLocation:self.currentLocation];

            detailLabel.text = [self.distanceFormatter stringFromDistance:dist];
        }

        return view;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {

    for (PlaceOfInterest *poi in self.foundPOIs) {
        
        if (poi == view.annotation) {

            [mapView removeAnnotation:poi];
            
            NSMutableArray<PlaceOfInterest *> *pois = [NSMutableArray arrayWithArray:self.foundPOIs];
            
            [pois removeObject:poi];
            self.foundPOIs = pois;
            
            break;
        }
    }
}

#pragma mark - UISearchBarDelegate protocol

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    [searchBar resignFirstResponder];
    
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    
    request.naturalLanguageQuery = searchBar.text;
    request.region = self.mapView.region;

    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        
        // Create a POI for each found item
        //
        NSMutableArray<PlaceOfInterest *> *places = [NSMutableArray array];

        for (MKMapItem *item in response.mapItems) {
            
            PlaceOfInterest *poi = [PlaceOfInterest placeOfInterestWithPlacemark:item.placemark];

            CLLocationDistance dist = [item.placemark.location distanceFromLocation:self.currentLocation];

            poi.title = [NSString stringWithFormat:@"%@ (%@)", item.name, [self.distanceFormatter stringFromDistance:dist]];
            
            [places addObject:poi];
        }

        [self.mapView removeAnnotations:[self.mapView annotations]];
        [self.mapView showAnnotations:places animated:YES];
        
        self.foundPOIs = places;
    }];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {

    [searchBar resignFirstResponder];
}

#pragma mark - Notification handlers

- (void)keyboardWillShow:(NSNotification *)notification {
    
    [self.searchBar setShowsCancelButton:YES animated:YES];
    
    NSValue *value = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect frame = [value CGRectValue];
    
    self.searchBarBottomLayoutConstraint.constant = frame.size.height;

    if (@available(iOS 11, *)) self.searchBarBottomLayoutConstraint.constant -= self.view.safeAreaInsets.bottom;

    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];

    [UIView animateWithDuration:duration
                          delay:0
                        options:animationOptionsWithCurve(curve)
                     animations:^ (void) {
                         
                         [self.view layoutIfNeeded];

                     } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    
    [self.searchBar setShowsCancelButton:NO animated:YES];

    self.searchBarBottomLayoutConstraint.constant = 0;
    
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:animationOptionsWithCurve(curve)
                     animations:^ (void) {
                         
                         [self.view layoutIfNeeded];
                         
                     } completion:nil];
}

@end
