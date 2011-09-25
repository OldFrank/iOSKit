// Part of iOSKit http://foundationk.it
//
// Derived from Sam Soffes' Custom-Licensed SSToolkit: http://github.com/samsoffes/sstoolkit

#import <UIKit/UIKit.h>

/**
 This category adds support for getting orientation-aware screen bounds as well as a safe
 check for retinaDisplays.
 */

@interface UIScreen (FKAdditions)

@property (nonatomic, readonly) CGRect currentBounds;
@property (nonatomic, readonly) BOOL isRetinaDisplay;

- (CGRect)boundsForOrientation:(UIInterfaceOrientation)orientation;

@end
