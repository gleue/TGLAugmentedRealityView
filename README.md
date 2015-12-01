TGLAugmentedRealityView
=======================

Place overlays on a camera preview and adjust their position depending on device attitude.

<p align="center">
<img src="https://raw.github.com/gleue/TGLAugmentedRealityView/master/Screenshots/TGLAugmentedRealityExample.jpg" alt="TGLAugmentedRealityExample" title="TGLAugmentedRealityExample">
</p>

Getting Started
===============

Take a look at sample project `TGLAugmentedRealityExample.xcodeproj`.

Usage
=====

Via [CocoaPods](http://cocoapods.org):

* Add `pod 'TGLAugmentedRealityView', '~> 1.0'` to your project's `Podfile`

Or the "classic" way:

* Add files in folder `TGLAugmentedRealityView` to your project

Then in your project:

* Implement `TGLARViewDataSource` and `TGLARViewDelegate` protocols
* Place a `TGLARView` in your storyboard and set its `-dataSource` and `-delegate` outlets

Optionally:

* Implement `TGLARCompass` protocol
* Set `TGLARView`'s `-compass` outlet

Sample
======

Build and run `TGLAugmentedRealityExample.xcodeproj` on an iDevice. The app will run on the
simulator, too, but will give you no camera image or device orientation.

Tap the blue button and search for POIs in the map view. When finished, close the map to
reveal the AR view. The POIs will be displayed with a callout and a billboard image.

On the AR view use a horizontal pan gesture to adjust the compass heading and a pinch
gesture to adjust the zoom factor, if available in the active video format.

Requirements
============

* ARC
* iOS >= 8.0
* Xcode 7.1

License
=======

TGLAugmentedRealityView is available under the MIT License (MIT)

Copyright (c) 2015 Tim Gleue (http://gleue-interactive.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
