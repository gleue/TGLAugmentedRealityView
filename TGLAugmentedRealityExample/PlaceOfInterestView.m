//
//  PlaceOfInterestView.m
//  TGLAugmentedRealityExample
//
//  Created by Tim Gleue on 20.11.15.
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

#import "PlaceOfInterestView.h"

@interface PlaceOfInterestView ()

@property (nonatomic, weak) UILabel *overlayLabel;
@property (nonatomic, weak) UIButton *overlayButton;

@end

@implementation PlaceOfInterestView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    
    if (self) [self initView];
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    
    if (self) [self initView];
    
    return self;
}

- (void)initView {

    UILabel *overlayLabel = [[UILabel alloc] init];
    
    overlayLabel.textColor = [UIColor whiteColor];
    overlayLabel.numberOfLines = 0;
    overlayLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.contentView addSubview:overlayLabel];

    UIButton *overlayButton = [UIButton buttonWithType:UIButtonTypeInfoLight];

    overlayButton.tintColor = overlayLabel.textColor;
    overlayButton.translatesAutoresizingMaskIntoConstraints = NO;

    [overlayButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.contentView addSubview:overlayButton];
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[overlayButton]-[overlayLabel]-|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(overlayLabel, overlayButton)]];
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[overlayLabel]-|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(overlayLabel, overlayButton)]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:overlayButton
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0
                                                                  constant:0]];
    self.overlayLabel = overlayLabel;
    self.overlayButton = overlayButton;
}

#pragma mark - Accessors

- (void)setPlace:(PlaceOfInterest *)place {
    
    _place = place;
    
    self.overlayLabel.text = place.title;
}

#pragma mark - Actions

- (IBAction)buttonTapped:(id)sender {

    [self.delegate poiViewButtonTapped:self];
}

@end
