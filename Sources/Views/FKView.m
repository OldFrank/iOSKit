#import "FKView.h"
#import "FKShorthands.h"

@implementation FKView

@synthesize drawingBlock = drawingBlock_;

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

+ (id)viewWithFrame:(CGRect)frame drawingBlock:(fk_draw_block)block {
    FKView *view = [[[self class] alloc] initWithFrame:frame];
    view.drawingBlock = block;
    
    return view;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIView
////////////////////////////////////////////////////////////////////////

- (void)drawRect:(CGRect)rect {
    FKAssert(self.drawingBlock != nil, @"Drawing block must be set");
    
    if (self.drawingBlock != nil) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextSaveGState(context);
        self.drawingBlock(self, context);
        CGContextRestoreGState(context);
    }
}

@end
