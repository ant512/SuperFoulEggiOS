#import "CCLayer.h"

#import "cocos2d.h"
#import "SZMenuRectLayer.h"

@interface SZGameOptionsMenuLayer : CCLayer {
	SZMenuRectLayer *_rectLayer;
	NSMutableArray *_options;
}

+ (CCScene*)scene;
- (id)init;
- (void)loadBackground;

@end
