#import "SZGameOptionsMenuLayer.h"
#import "SZGameTypeMenuLayer.h"
#import "SimpleAudioEngine.h"
#import "CDAudioManager.h"
#import "CocosDenshion.h"
#import "SZPad.h"
#import "SZSettings.h"
#import "CCDirector.h"
#import "SZGameLayer.h"
#import "SZMenuRectLayer.h"
#import "SZGameOptionsMenuLayer.h"
#import "SZUIConstants.h"

#import <Foundation/Foundation.h>

@implementation SZGameOptionsMenuLayer

+ (CCScene *)scene {
	
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	SZGameOptionsMenuLayer *layer = [SZGameOptionsMenuLayer node];
	
	// add layer as a child to scene
	[scene addChild:layer];
	
	// return the scene
	return scene;
}

- (void)onEnter {
	[_rectLayer clearSelectionInGroup:4];
	[_rectLayer clearSelectionInGroup:5];
	[super onEnter];
}

- (void)addOptionRangeFrom:(int)start to:(int)end step:(int)step atY:(int)y withTitle:(NSString *)title {
	
	const int width = 60;
	const int height = 60;
	int x = (self.boundingBox.size.width - (width * ((end - start) / step + 1))) / 2;
	
	[self addCentredShadowedLabelWithString:title atY:y + height];
	
	int midPoint = -1;
	
	if (end - start > 5) {
		midPoint = start + ((end - start) / 2) + 1;
		
		x = (self.boundingBox.size.width - (width * (midPoint - start))) / 2;
	}
	
	NSMutableArray *rectangles = [NSMutableArray array];
	
	for (int i = start; i <= end; i += step) {
		if (i == midPoint) {
			y -= height;
			x = (self.boundingBox.size.width - (width * (midPoint - start))) / 2;
		}
		
		[self addLabelWithString:[[NSNumber numberWithInt:i] stringValue] atX:x + (width / 2) y:y];
		[rectangles addObject:[NSValue valueWithCGRect:CGRectMake(x, y - (height / 2), width, height)]];
		
		x += width;
	}
	
	[_rectLayer.rectangleGroups addObject:rectangles];
}

- (void)addOption:(NSString *)option atX:(int)x y:(int)y width:(int)width height:(int)height {

	[self addLabelWithString:option atX:x + (width / 2) y:y + (height / 5)];

	NSMutableArray *group = [NSMutableArray array];

	[_rectLayer.rectangleGroups addObject:group];

	[group addObject:[NSValue valueWithCGRect:CGRectMake(x, y - 40, width, height)]];
}

- (id)init {
	
	if ((self = [super init])) {

		self.touchEnabled = YES;
		
		_options = [[NSMutableArray array] retain];
		
		[self loadBackground];
		
		_rectLayer = [[SZMenuRectLayer alloc] init];
		[self addChild:_rectLayer];
		
		[self addOptionRangeFrom:0 to:9 step:1 atY:650 withTitle:@"Speed"];
		[self addOptionRangeFrom:0 to:9 step:1 atY:450 withTitle:@"Height"];
		[self addOptionRangeFrom:4 to:6 step:1 atY:250 withTitle:@"Colours"];
		[self addOptionRangeFrom:3 to:7 step:2 atY:100 withTitle:@"Best Of"];

		[self addOption:@"Back" atX:150 y:100 width:200 height:100];
		[self addOption:@"Start" atX:670 y:100 width:200 height:100];
		
		if (![[SimpleAudioEngine sharedEngine] isBackgroundMusicPlaying]) {
			[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"title.mp3"];
		}
		
		[_rectLayer.selectedRectangleIndexes setObject:[NSNumber numberWithInt:[SZSettings sharedSettings].speed] atIndexedSubscript:0];
		[_rectLayer.selectedRectangleIndexes setObject:[NSNumber numberWithInt:[SZSettings sharedSettings].height] atIndexedSubscript:1];
		[_rectLayer.selectedRectangleIndexes setObject:[NSNumber numberWithInt:[SZSettings sharedSettings].eggColours - 4] atIndexedSubscript:2];
		[_rectLayer.selectedRectangleIndexes setObject:[NSNumber numberWithInt:([SZSettings sharedSettings].gamesPerMatch - 3) / 2] atIndexedSubscript:3];
	}
	
	return self;
}

- (void)dealloc {
	[_options release];
	[_rectLayer release];
	
	_options = nil;
	_rectLayer = nil;
	
	[super dealloc];
}

- (void)addCentredShadowedLabelWithString:(NSString *)text atY:(CGFloat)y {
	CCLabelBMFont *shadow = [CCLabelBMFont labelWithString:text fntFile:@"font.fnt"];
	CCLabelBMFont *label = [CCLabelBMFont labelWithString:text fntFile:@"font.fnt"];

	[shadow.texture setAliasTexParameters];
	[label.texture setAliasTexParameters];
	
	shadow.position = CGPointMake((self.boundingBox.size.width / 2) - SZShadowOffset, y - SZShadowOffset);
	
	ccColor3B color;
	color.b = 0;
	color.g = 0;
	color.r = 0;
	
	shadow.color = color;
	shadow.opacity = 192;
	
	label.position = CGPointMake(self.boundingBox.size.width / 2, y);
	
	[self addChild:shadow];
	[self addChild:label];
}

- (void)addLabelWithString:(NSString *)text atX:(CGFloat)x y:(CGFloat)y {
	CCLabelBMFont *shadow = [CCLabelBMFont labelWithString:text fntFile:@"font.fnt"];
	CCLabelBMFont *label = [CCLabelBMFont labelWithString:text fntFile:@"font.fnt"];

	[shadow.texture setAliasTexParameters];
	[label.texture setAliasTexParameters];
	
	shadow.position = CGPointMake(x - SZShadowOffset, y - SZShadowOffset);
	
	ccColor3B color;
	color.b = 0;
	color.g = 0;
	color.r = 0;
	
	shadow.color = color;
	shadow.opacity = 192;
	
	label.position = CGPointMake(x, y);
	
	[self addChild:shadow];
	[self addChild:label];
}

- (void)loadBackground {
	int x = [[CCDirector sharedDirector] winSize].width / 2;
	int y = [[CCDirector sharedDirector] winSize].height / 2;
	
	CCSprite* background = [CCSprite spriteWithFile:@"menubackground.png"];
	background.position = ccp(x, y);
	[background.texture setAliasTexParameters];
	[self addChild:background z:0];
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

	UITouch *touch = [touches allObjects][0];

	CGPoint point = [touch locationInView:[[CCDirector sharedDirector] view]];

	point.y = [CCDirector sharedDirector].winSize.height - point.y;

	if ([_rectLayer selectRectangleAtPoint:point]) {

		[[SimpleAudioEngine sharedEngine] playEffect:@"rotate.wav"];
		
		[SZSettings sharedSettings].speed = [_rectLayer selectedIndexInGroup:0];
		[SZSettings sharedSettings].height = [_rectLayer selectedIndexInGroup:1];
		[SZSettings sharedSettings].eggColours = [_rectLayer selectedIndexInGroup:2] + 4;
		[SZSettings sharedSettings].gamesPerMatch = ([_rectLayer selectedIndexInGroup:3] * 2) + 3;

		if (_rectLayer.selectedGroupIndex == 4) {
			[[CCDirector sharedDirector] replaceScene:[SZGameTypeMenuLayer scene]];
		} else if (_rectLayer.selectedGroupIndex == 5) {
			[[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
			[[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.5f scene:[SZGameLayer scene]]];
		}
	}
	
	[[SZSettings sharedSettings] save];
}

@end
