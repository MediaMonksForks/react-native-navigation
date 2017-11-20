//
//

#import <objc/runtime.h>
#import "UINavigationBar+RCCNavigationBar.h"

static char const *const heightKey = "UINavigationBar+RCCNavigationBar.Height";

@implementation UINavigationBar (RCCNavigationBar)

- (void)setHeight:(CGFloat)height
{
	objc_setAssociatedObject(self, heightKey, @(height), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)height
{
	return objc_getAssociatedObject(self, heightKey);
}

- (CGSize)sizeThatFits:(CGSize)size
{
	if (self.height) {
		return CGSizeMake(self.superview.bounds.size.width, self.height.floatValue);
	} else {
		return [super sizeThatFits:size];
	}
}

@end
