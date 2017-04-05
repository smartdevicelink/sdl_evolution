# Manual layout for `SDLLockScreenViewController`

* Proposal: [SDL-0047](0047-manual-lockscreen-layout-ios.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **In Review**
* Impacted Platforms: iOS

## Introduction
This feature is to turn all lock screen related layouts and assets into code. This would simplify developers’ implementation of SDL; they would no longer have to import SDL lock screen assets into their project separately from the code.

## Motivation
Currently, SDL lock screen assets, such as layout storyboards and images, have to be packaged separately from the rest of the iOS library. Developers implementing the iOS library therefore have separate work to do in order to import the assets into their project, particularly when developers use Cocoapods to manage their SDL iOS dependency. Furthermore, currently, if we wish to update our assets in any way, they have to be re-imported by developers.

This is what is currently written in the iOS README:

```markdown
If you used CocoaPods to install the SDL SDK, you must complete the following steps to add the default lock screen resources to your project:

1. Select your application's build target, go to Build Phases, Copy Bundle Resources.
2. Then in the Navigator window of Xcode, go to Target's Support Files, Pods-YourProjectName, and drag and drop the SmartDeviceLink.bundle file into Copy Bundle Resources.
3. After the bundle is dropped into Copy Bundle Resources check "copy items if need" from the popup box and click "Finish."
```

## Proposed solution
The proposed solution is two-fold. First, re-create the layout of `SDLLockScreenViewController` which is currently setup in `SDLLockScreen.storyboard` to be laid out in code instead using the `NSLayoutConstraint` API. Second, re-create our image assets into code using the app Paintcode. Livio already has a license for this app, and it would allow us to convert SVG assets into idiomatic Objective-C code.

An example of the code that is generated for the SDL Logo currently used in the `SDLLockScreenViewController`:

```objc
// SDLLogo.h
typedef enum : NSInteger
{
    SDLLogoResizingBehaviorAspectFit, //!< The content is proportionally resized to fit into the target rectangle.
    SDLLogoResizingBehaviorAspectFill, //!< The content is proportionally resized to completely fill the target rectangle.
    SDLLogoResizingBehaviorStretch, //!< The content is stretched to match the entire target rectangle.
    SDLLogoResizingBehaviorCenter, //!< The content is centered in the target rectangle, but it is NOT resized.

} SDLLogoResizingBehavior;

extern CGRect SDLLogoResizingBehaviorApply(SDLLogoResizingBehavior behavior, CGRect rect, CGRect target);


@interface SDLLogo : NSObject

// Drawing Methods
+ (void)drawSDLLogo;
+ (void)drawSDLLogoWithFrame: (CGRect)targetFrame resizing: (SDLLogoResizingBehavior)resizing;

@end
```

```objc
// SDLLogo.m
#import "SDLLogo.h"

@implementation SDLLogo

#pragma mark Initialization

+ (void)initialize
{
}

#pragma mark Drawing Methods

+ (void)drawSDLLogo
{
    [SDLLogo drawCanvas1WithFrame: CGRectMake(0, 0, 249, 120) resizing: SDLLogoResizingBehaviorStretch];
}

+ (void)drawSDLLogoWithFrame: (CGRect)targetFrame resizing: (SDLLogoResizingBehavior)resizing
{
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();

    //// Resize to Target Frame
    CGContextSaveGState(context);
    CGRect resizedFrame = SDLLogoResizingBehaviorApply(resizing, CGRectMake(0, 0, 249, 120), targetFrame);
    CGContextTranslateCTM(context, resizedFrame.origin.x, resizedFrame.origin.y);
    CGContextScaleCTM(context, resizedFrame.size.width / 249, resizedFrame.size.height / 120);


    //// Color Declarations
    UIColor* fillColor = [UIColor colorWithRed: 0.239 green: 0.238 blue: 0.267 alpha: 1];

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(55.7, 8.5)];
    [bezierPath addLineToPoint: CGPointMake(55.6, 8.4)];
    [bezierPath addLineToPoint: CGPointMake(0.2, 31.7)];
    [bezierPath addLineToPoint: CGPointMake(0.2, 88.2)];
    [bezierPath addLineToPoint: CGPointMake(55.5, 111.5)];
    [bezierPath addLineToPoint: CGPointMake(55.6, 111.6)];
    [bezierPath addLineToPoint: CGPointMake(111, 88.3)];
    [bezierPath addLineToPoint: CGPointMake(111, 31.7)];
    [bezierPath addLineToPoint: CGPointMake(55.7, 8.5)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(71.7, 70.9)];
    [bezierPath addLineToPoint: CGPointMake(55.5, 77.7)];
    [bezierPath addLineToPoint: CGPointMake(7.7, 57.5)];
    [bezierPath addLineToPoint: CGPointMake(7.7, 36.7)];
    [bezierPath addLineToPoint: CGPointMake(55.6, 16.5)];
    [bezierPath addLineToPoint: CGPointMake(103.5, 36.7)];
    [bezierPath addLineToPoint: CGPointMake(103.5, 54.3)];
    [bezierPath addLineToPoint: CGPointMake(55.7, 34.2)];
    [bezierPath addLineToPoint: CGPointMake(55.6, 34.1)];
    [bezierPath addLineToPoint: CGPointMake(20.1, 49.1)];
    [bezierPath addLineToPoint: CGPointMake(71.7, 70.9)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(103.5, 62.5)];
    [bezierPath addLineToPoint: CGPointMake(103.5, 83.3)];
    [bezierPath addLineToPoint: CGPointMake(55.6, 103.5)];
    [bezierPath addLineToPoint: CGPointMake(7.7, 83.3)];
    [bezierPath addLineToPoint: CGPointMake(7.7, 65.6)];
    [bezierPath addLineToPoint: CGPointMake(55.5, 85.7)];
    [bezierPath addLineToPoint: CGPointMake(55.6, 85.8)];
    [bezierPath addLineToPoint: CGPointMake(91, 70.9)];
    [bezierPath addLineToPoint: CGPointMake(39.4, 49.1)];
    [bezierPath addLineToPoint: CGPointMake(55.6, 42.3)];
    [bezierPath addLineToPoint: CGPointMake(103.5, 62.5)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(139.9, 69.7)];
    [bezierPath addLineToPoint: CGPointMake(149.4, 69.7)];
    [bezierPath addCurveToPoint: CGPointMake(159.3, 76.2) controlPoint1: CGPointMake(150.1, 74.2) controlPoint2: CGPointMake(154.4, 76.2)];
    [bezierPath addCurveToPoint: CGPointMake(166.8, 71.4) controlPoint1: CGPointMake(163.4, 76.2) controlPoint2: CGPointMake(166.8, 75.1)];
    [bezierPath addCurveToPoint: CGPointMake(161.1, 66.6) controlPoint1: CGPointMake(166.8, 68.3) controlPoint2: CGPointMake(164.1, 67.4)];
    [bezierPath addLineToPoint: CGPointMake(152.5, 64.4)];
    [bezierPath addCurveToPoint: CGPointMake(141, 50.8) controlPoint1: CGPointMake(146.5, 62.9) controlPoint2: CGPointMake(141, 59.6)];
    [bezierPath addCurveToPoint: CGPointMake(157.5, 37.4) controlPoint1: CGPointMake(141, 41.8) controlPoint2: CGPointMake(148.2, 37.4)];
    [bezierPath addCurveToPoint: CGPointMake(174.9, 51.9) controlPoint1: CGPointMake(167.3, 37.4) controlPoint2: CGPointMake(174.1, 41.8)];
    [bezierPath addLineToPoint: CGPointMake(165.2, 51.9)];
    [bezierPath addCurveToPoint: CGPointMake(156.8, 46.3) controlPoint1: CGPointMake(164.5, 47.9) controlPoint2: CGPointMake(161.1, 46.3)];
    [bezierPath addCurveToPoint: CGPointMake(150.3, 51) controlPoint1: CGPointMake(154, 46.3) controlPoint2: CGPointMake(150.3, 47.4)];
    [bezierPath addCurveToPoint: CGPointMake(155.4, 55.2) controlPoint1: CGPointMake(150.3, 53.7) controlPoint2: CGPointMake(152.9, 54.6)];
    [bezierPath addLineToPoint: CGPointMake(163.8, 57.3)];
    [bezierPath addCurveToPoint: CGPointMake(176.2, 71.6) controlPoint1: CGPointMake(172.1, 59.4) controlPoint2: CGPointMake(176.2, 62.9)];
    [bezierPath addCurveToPoint: CGPointMake(159.3, 85) controlPoint1: CGPointMake(176.1, 80.6) controlPoint2: CGPointMake(169.2, 85)];
    [bezierPath addCurveToPoint: CGPointMake(139.9, 69.7) controlPoint1: CGPointMake(148.8, 85.1) controlPoint2: CGPointMake(140.5, 80.1)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(184.4, 56.4)];
    [bezierPath addCurveToPoint: CGPointMake(202.5, 37.6) controlPoint1: CGPointMake(184.4, 42.4) controlPoint2: CGPointMake(194.6, 37.6)];
    [bezierPath addCurveToPoint: CGPointMake(213.1, 42.8) controlPoint1: CGPointMake(207.3, 37.6) controlPoint2: CGPointMake(211.8, 40.2)];
    [bezierPath addLineToPoint: CGPointMake(213.1, 22.5)];
    [bezierPath addLineToPoint: CGPointMake(222.3, 22.5)];
    [bezierPath addLineToPoint: CGPointMake(222.3, 84.2)];
    [bezierPath addLineToPoint: CGPointMake(213, 84.2)];
    [bezierPath addLineToPoint: CGPointMake(213, 79.9)];
    [bezierPath addCurveToPoint: CGPointMake(202.4, 85.1) controlPoint1: CGPointMake(211.7, 82.5) controlPoint2: CGPointMake(207.2, 85.1)];
    [bezierPath addCurveToPoint: CGPointMake(184.3, 66.2) controlPoint1: CGPointMake(194.6, 85.1) controlPoint2: CGPointMake(184.3, 80.3)];
    [bezierPath addLineToPoint: CGPointMake(184.3, 56.4)];
    [bezierPath addLineToPoint: CGPointMake(184.4, 56.4)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(193.6, 66)];
    [bezierPath addCurveToPoint: CGPointMake(202.7, 76) controlPoint1: CGPointMake(193.6, 72.9) controlPoint2: CGPointMake(197.6, 76)];
    [bezierPath addCurveToPoint: CGPointMake(213, 66) controlPoint1: CGPointMake(208.4, 76) controlPoint2: CGPointMake(213, 72.8)];
    [bezierPath addLineToPoint: CGPointMake(213, 56.5)];
    [bezierPath addCurveToPoint: CGPointMake(203.3, 46.5) controlPoint1: CGPointMake(213, 49.6) controlPoint2: CGPointMake(209, 46.5)];
    [bezierPath addCurveToPoint: CGPointMake(193.6, 56.5) controlPoint1: CGPointMake(197.6, 46.5) controlPoint2: CGPointMake(193.6, 49.7)];
    [bezierPath addLineToPoint: CGPointMake(193.6, 66)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(243.5, 71)];
    [bezierPath addCurveToPoint: CGPointMake(247.7, 75.3) controlPoint1: CGPointMake(243.5, 74.3) controlPoint2: CGPointMake(244.1, 75.3)];
    [bezierPath addLineToPoint: CGPointMake(249.1, 75.3)];
    [bezierPath addLineToPoint: CGPointMake(249.1, 84.2)];
    [bezierPath addLineToPoint: CGPointMake(245, 84.2)];
    [bezierPath addCurveToPoint: CGPointMake(234.2, 73.4) controlPoint1: CGPointMake(237.4, 84.2) controlPoint2: CGPointMake(234.2, 80.5)];
    [bezierPath addLineToPoint: CGPointMake(234.2, 22.5)];
    [bezierPath addLineToPoint: CGPointMake(243.4, 22.5)];
    [bezierPath addLineToPoint: CGPointMake(243.4, 71)];
    [bezierPath addLineToPoint: CGPointMake(243.5, 71)];
    [bezierPath closePath];
    [fillColor setFill];
    [bezierPath fill];

    CGContextRestoreGState(context);

}

@end



CGRect SDLLogoResizingBehaviorApply(SDLLogoResizingBehavior behavior, CGRect rect, CGRect target)
{
    if (CGRectEqualToRect(rect, target) || CGRectEqualToRect(target, CGRectZero))
        return rect;

    CGSize scales = CGSizeZero;
    scales.width = ABS(target.size.width / rect.size.width);
    scales.height = ABS(target.size.height / rect.size.height);

    switch (behavior)
    {
        case SDLLogoResizingBehaviorAspectFit:
        {
            scales.width = MIN(scales.width, scales.height);
            scales.height = scales.width;
            break;
        }
        case SDLLogoResizingBehaviorAspectFill:
        {
            scales.width = MAX(scales.width, scales.height);
            scales.height = scales.width;
            break;
        }
        case SDLLogoResizingBehaviorStretch:
            break;
        case SDLLogoResizingBehaviorCenter:
        {
            scales.width = 1;
            scales.height = 1;
            break;
        }
    }

    CGRect result = CGRectStandardize(rect);
    result.size.width *= scales.width;
    result.size.height *= scales.height;
    result.origin.x = target.origin.x + (target.size.width - result.size.width) / 2;
    result.origin.y = target.origin.y + (target.size.height - result.size.height) / 2;
    return result;
}
```

Creating assets in this way should also slightly improve the size of data we require developers to import in order to use the library. They are also more flexible, as these assets can change color and more easily scale than PNG assets.

Laying out the lock screen via code has advantages as well. We have seen warnings due to backward compatibility with storyboards, by using raw code to lay out the screen, we would avoid this. Developers unfamiliar with storyboards would be able to more easily understand and modify how it is laid out as well.

## Potential downsides
A potential downside of this proposal is that future updates will require maintainers to use something like Paintcode to generate code such as the above to use future assets in the same way as we do now.

A second potential downside is that for those who do know storyboards, or for designers, the storyboard layout of the lock screen is easier to understand visually than the code version would be.

## Impact on existing code
This would remove an integration step by developers, therefore, current developers would need to know to remove the old assets from their project. Furthermore, beyond the obvious work to be done to lay out the lock screen and to add the new code version of the assets, there would be some additional code changes to integrate those changes, but these would mostly be simplification of code, not expansion.

## Alternatives considered
We could certainly keep the same approach as currently exists, but the advantage of removing steps for developers to implement SDL, the benefits of simplicity by making everything code, and the advantage of scalable and flexible assets makes this proposal a worthwhile addition.

We could also choose only one aspect of the proposal or the other, between the layout and the assets. But if we only choose one, then we do not gain the benefits of removing an integration step for developers.
