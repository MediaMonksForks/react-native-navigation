//
//

#import <objc/runtime.h>
#import "UINavigationBar+RCCNavigationBar.h"

static char const *const heightKey = "UINavigationBar+RCCNavigationBar.Height";

@implementation UINavigationBar (RCCNavigationBar)

- (void)setHeight:(CGFloat)height
{
	objc_setAssociatedObject(self, heightKey, @(height), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self sizeToFit];
	[self setNeedsLayout];
}

- (NSNumber *)height
{
	return objc_getAssociatedObject(self, heightKey);
}

- (CGSize)sizeThatFits:(CGSize)size
{
	CGSize cgSize = [super sizeThatFits:size];
	if (self.height) {
		return CGSizeMake(cgSize.width, self.height.floatValue);
	} else {
		return cgSize;
	}
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
	return UIBarPositionTopAttached;
}

@end
