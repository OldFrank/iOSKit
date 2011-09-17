// Part of iOSKit http://foundationk.it

#import <UIKit/UIKit.h>

@interface UIImageView (FKAdditions)

+ (UIImageView *)imageViewNamed:(NSString *)imageName;

- (void)setImage:(UIImage *)image animated:(BOOL)animated;
- (void)setImage:(UIImage *)image duration:(NSTimeInterval)duration;

@end