#import "UIScrollView+FKAdditions.h"

FKLoadCategory(UIScrollViewFKAdditions);

@implementation UIScrollView (FKAdditions)

- (void)scrollToTop {
	[self scrollToTopAnimated:NO];
}

- (void)scrollToTopAnimated:(BOOL)animated {
	[self setContentOffset:CGPointMake(0.f, 0.f) animated:animated];
}

- (void)setContentAndScrollIndicatorInset:(UIEdgeInsets)contentInset {
    self.contentInset = contentInset;
    self.scrollIndicatorInsets = contentInset;
}

@end
