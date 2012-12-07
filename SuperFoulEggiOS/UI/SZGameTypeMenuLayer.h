#import <Foundation/Foundation.h>

#import "cocos2d.h"
#import "SZMenuRectLayer.h"

@interface SZGameTypeMenuLayer : CCLayer {
	SZMenuRectLayer *_rectLayer;
	NSMutableArray *_options;
	NSString *_title;
}

@property (readwrite, retain, nonatomic) NSString *title;

+ (CCScene *)scene;
- (id)init;
- (void)loadBackground;
- (void)addOption:(NSString *)option;

@end
