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
#import "SZNetworkSession.h"

@implementation SZGameTypeMenuLayer

@synthesize title = _title;

+ (CCScene *)scene {
	
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	SZGameTypeMenuLayer *layer = [SZGameTypeMenuLayer node];
	
	// add layer as a child to scene
	[scene addChild:layer];
	
	// return the scene
	return scene;
}

- (void)addOption:(NSString *)option {
	
	int width = 340;
	int height = 80;

	int y = self.boundingBox.size.height - 200 - (80 * _options.count);
	int x = (self.boundingBox.size.width - width) / 2;
	
	[self addCentredShadowedLabelWithString:option atY:y];
	
	if (_rectLayer.rectangleGroups.count == 0) {
		[_rectLayer.rectangleGroups addObject:[NSMutableArray array]];
	}
	
	[[_rectLayer.rectangleGroups objectAtIndex:0] addObject:[NSValue valueWithCGRect:CGRectMake(x, y - 40, width, height)]];
	[_options addObject:option];
}

- (id)init {
	
	if ((self = [super init])) {

		self.touchEnabled = YES;
		
		_options = [[NSMutableArray array] retain];
		_title = @"Game Type";
		
		[self loadBackground];
		
		_rectLayer = [[SZMenuRectLayer alloc] init];
		[self addChild:_rectLayer];
		
		[self addCentredShadowedLabelWithString:_title atY:self.boundingBox.size.height - 100];
		
		[self addOption:@"Practice"];
		[self addOption:@"Easy"];
		[self addOption:@"Medium"];
		[self addOption:@"Hard"];
		[self addOption:@"Insane"];
		[self addOption:@"2 Player"];
		
		switch ([SZSettings sharedSettings].gameType) {
			case SZGameTypePractice:
				[_rectLayer.selectedRectangleIndexes setObject:@0 atIndexedSubscript:0];

				break;
			case SZGameTypeSinglePlayer:
				switch ([SZSettings sharedSettings].aiType) {
					case SZAITypeEasy:
						[_rectLayer.selectedRectangleIndexes setObject:@1 atIndexedSubscript:0];
						break;
					case SZAITypeMedium:
						[_rectLayer.selectedRectangleIndexes setObject:@2 atIndexedSubscript:0];
						break;
					case SZAITypeHard:
						[_rectLayer.selectedRectangleIndexes setObject:@3 atIndexedSubscript:0];
						break;
					case SZAITypeInsane:
						[_rectLayer.selectedRectangleIndexes setObject:@4 atIndexedSubscript:0];
						break;
				}
				break;
			case SZGameTypeTwoPlayer:
				[_rectLayer.selectedRectangleIndexes setObject:@5 atIndexedSubscript:0];
				break;
		}
		
		if (![[SimpleAudioEngine sharedEngine] isBackgroundMusicPlaying]) {
			[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"title.mp3"];
		}
	}
	
	return self;
}

- (void)dealloc {
	[_options release];
	[_title release];
	[_rectLayer release];
	
	_options = nil;
	_title = nil;
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

- (void)loadBackground {
	int x = [[CCDirector sharedDirector] winSize].width / 2;
	int y = [[CCDirector sharedDirector] winSize].height / 2;
	
	CCSprite *background = [CCSprite spriteWithFile:@"menubackground.png"];
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
		
		switch ([_rectLayer selectedIndexInGroup:0]) {
			case 0:
				[SZSettings sharedSettings].gameType = SZGameTypePractice;
				break;
			case 1:
				[SZSettings sharedSettings].gameType = SZGameTypeSinglePlayer;
				[SZSettings sharedSettings].aiType = SZAITypeEasy;
				break;
			case 2:
				[SZSettings sharedSettings].gameType = SZGameTypeSinglePlayer;
				[SZSettings sharedSettings].aiType = SZAITypeMedium;
				break;
			case 3:
				[SZSettings sharedSettings].gameType = SZGameTypeSinglePlayer;
				[SZSettings sharedSettings].aiType = SZAITypeHard;
				break;
			case 4:
				[SZSettings sharedSettings].gameType = SZGameTypeSinglePlayer;
				[SZSettings sharedSettings].aiType = SZAITypeInsane;
				break;
			case 5:
				[SZSettings sharedSettings].gameType = SZGameTypeTwoPlayer;
				[[SZNetworkSession sharedSession] startWithPlayerCount:2];
				break;
		}
		
		[[CCDirector sharedDirector] replaceScene:[SZGameOptionsMenuLayer scene]];
	}
	
	[[SZSettings sharedSettings] save];
}

@end
