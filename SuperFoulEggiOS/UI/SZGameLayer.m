#import <Foundation/Foundation.h>

#import "cocos2d.h"
#import "SimpleAudioEngine.h"
#import "CDAudioManager.h"
#import "CocosDenshion.h"

#import "SZGameLayer.h"
#import "SZPlayerOneController.h"
#import "SZPad.h"
#import "SZPoint.h"
#import "SZEggFactory.h"

#import "SZEggBase.h"
#import "SZRedEgg.h"
#import "SZGreenEgg.h"
#import "SZBlueEgg.h"
#import "SZPurpleEgg.h"
#import "SZYellowEgg.h"
#import "SZOrangeEgg.h"
#import "SZGarbageEgg.h"
#import "SZGridBottomEgg.h"
#import "SZGridBottomLeftEgg.h"
#import "SZGridBottomRightEgg.h"

#import "SZEngineConstants.h"

#import "SZPad.h"
#import "SZSettings.h"
#import "SZNetworkSession.h"

#import "SZGameTypeMenuLayer.h"

#import "CCNode+SFGestureRecognizers.h"

const int SZFrameRate = 60;
const int SZGrid1X = 80;
const int SZGrid2X = 656;
const int SZGridY = 0;

const int SZNextEgg1X = 440;
const int SZNextEgg2X = 578;
const int SZNextEggY = -280;
const int SZGrid2TagX = 569;
const int SZGrid2TagY = 462;
const int SZGrid1MatchScoreX = 476;
const int SZGrid1GameScoreX = 563;
const int SZGrid1ScoresY = 363;
const int SZGrid2MatchScoreX = 509;
const int SZGrid2GameScoreX = 602;
const int SZGrid2ScoresY = 285;

@implementation SZGameLayer

+ (CCScene *)scene {
	
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	SZGameLayer *layer = [SZGameLayer node];
	
	// add layer as a child to scene
	[scene addChild:layer];
	
	// return the scene
	return scene;
}

- (id)init {
	if ((self = [super init])) {
		
		sranddev();
		
		self.touchEnabled = YES;

		_state = SZGameStateWaitingForEgg;
		
		UITapGestureRecognizer *clockwiseRotateTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleClockwiseRotateTap:)];
		
		clockwiseRotateTap.numberOfTouchesRequired = 1;
		
		[self addGestureRecognizer:clockwiseRotateTap];
		[clockwiseRotateTap release];

		UITapGestureRecognizer *antiClockwiseRotateTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleAntiClockwiseRotateTap:)];
		
		antiClockwiseRotateTap.numberOfTouchesRequired = 2;
		
		[self addGestureRecognizer:antiClockwiseRotateTap];
		[antiClockwiseRotateTap release];
		
		UISwipeGestureRecognizer *dropSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleDropSwipe:)];
		
		dropSwipe.numberOfTouchesRequired = 2;
		dropSwipe.direction = UISwipeGestureRecognizerDirectionDown;
		
		[self addGestureRecognizer:dropSwipe];
		[dropSwipe release];

		UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMovePan:)];

		pan.minimumNumberOfTouches = 1;
		pan.maximumNumberOfTouches = 1;

		[self addGestureRecognizer:pan];
		[pan release];
		
		int players = [SZSettings sharedSettings].gameType == SZGameTypePractice ? 1 : 2;

		[[SZEggFactory sharedFactory] setPlayerCount:players
									  eggColourCount:[SZSettings sharedSettings].eggColours
									 isNetworkActive:[SZSettings sharedSettings].gameType == SZGameTypeTwoPlayer];
		
		for (int i = 0; i < SZMaximumPlayers; ++i) {
			_matchWins[i] = 0;
			_gameWins[i] = 0;
		}
		
		[self loadBackground];
		[self prepareSpriteSheets];
		[self loadSounds];
		[self resetGame];
		[self createWinLabels];

		[self scheduleUpdate];
	}
	return self;
}

#pragma mark - Gesture recogniser handlers

- (void)handleClockwiseRotateTap:(UITapGestureRecognizer *)gesture {
	
	if (_didDrag) return;
	
	CGPoint point = [gesture locationInView:[CCDirector sharedDirector].view];
	
	if (_state == SZGameStatePaused || (point.x > 950 && point.y > 700)) {
		[[SZPad instanceOne] pressStart];
		return;
	}
	
	[[SZPad instanceOne] pressA];
	_columnTarget = -1;
	
	_didDrag = NO;
	_dragStartColumn = -1;
	_dragStartX = -1;
}

- (void)handleAntiClockwiseRotateTap:(UITapGestureRecognizer *)gesture {
	
	if (_didDrag) return;
	
	[[SZPad instanceOne] pressB];
	_columnTarget = -1;
	
	_didDrag = NO;
	_dragStartColumn = -1;
	_dragStartX = -1;
}

- (void)handleDropSwipe:(UISwipeGestureRecognizer *)gesture {
	
	if(_didDrag) return;

	[[SZPad instanceOne] pressDown];
	_columnTarget = -1;
	
	_didDrag = NO;
	_dragStartColumn = -1;
	_dragStartX = -1;
}

- (void)handleMovePan:(UIPanGestureRecognizer *)gesture {

	CGPoint point = [gesture locationInView:[[CCDirector sharedDirector] view]];

	switch (gesture.state) {
		case UIGestureRecognizerStateBegan:
			[self dragStarted:point];
			break;

		case UIGestureRecognizerStateChanged:
			[self dragMoved:point];
			break;

		case UIGestureRecognizerStateEnded:
			[self dragEnded];
			break;

		default:
			break;
	}
}

- (void)dragStarted:(CGPoint)point {
	_didDrag = NO;
	_dragStartColumn = -1;
	_dragStartX = -1;

	if (!_runners[0].grid.hasLiveEggs) return;

	int egg1X = [[_runners[0].grid liveEgg:0] x];
	int egg2X = [[_runners[0].grid liveEgg:1] x];

	// Remember the left-most column.  We'll drag relative to this.
	_dragStartColumn = egg1X < egg2X ? egg1X : egg2X;
	_dragStartX = point.x;
}

- (void)dragMoved:(CGPoint)point {
	
	if (_dragStartColumn == -1) return;
	
	int newColumnTarget = _dragStartColumn + ((point.x - _dragStartX) / SZEggSize);

	if (newColumnTarget == _dragStartColumn && !_didDrag) {

		// If the player hasn't moved horizontally a significant amount, this is
		// possibly a different gesture.  We can discard it.
		return;
	}

	_columnTarget = newColumnTarget;
	_didDrag = YES;
}

- (void)dragEnded {
	_didDrag = NO;
	_dragStartColumn = -1;
	_dragStartX = -1;
}

- (void)createNextEggSpriteConnectorPairForRunner:(SZGridRunner *)runner {

	int gridX = runner.playerNumber == 0 ? SZNextEgg1X : SZNextEgg2X;
	
	NSMutableArray *connectorArray = _eggSpriteConnectors[runner.playerNumber];
	
	// Create a new sprite for both next eggs
	for (int i = 0; i < 2; ++i) {
		[self createEggSpriteConnector:[runner nextEgg:i] gridX:gridX gridY:SZNextEggY connectorArray:connectorArray];
		gridX += SZEggSize;
	}
}

- (BOOL)moveNextEggToGridForPlayer:(int)playerNumber egg:(SZEggBase *)egg {
	int gridX = playerNumber == 0 ? SZGrid1X : SZGrid2X;
	
	NSMutableArray *connectorArray = _eggSpriteConnectors[playerNumber];
	
	// If there is already a connector for this egg, we need to adjust
	// its grid co-ordinates back to the real values.  At present the
	// co-ords are being abused to make the sprite appear in the "next
	// egg" location
	for (SZEggSpriteConnector *connector in connectorArray) {
		if (connector.egg == egg) {
			connector.gridX = gridX;
			connector.gridY = SZGridY;
			
			[connector updateSpritePosition];
			
			return YES;
		}
	}

	// No existing egg exists (this must be a garbage egg)
	return NO;
}

- (void)addEggSpriteConnectorForPlayer:(int)playerNumber egg:(SZEggBase *)egg {
	int gridX = playerNumber == 0 ? SZGrid1X : SZGrid2X;
	
	NSMutableArray *connectorArray = _eggSpriteConnectors[playerNumber];

	[self createEggSpriteConnector:egg gridX:gridX gridY:SZGridY connectorArray:connectorArray];
}

- (void)hitColumnWithGarbageForPlayerNumber:(int)playerNumber column:(int)column {
	for (SZEggSpriteConnector *connector in _eggSpriteConnectors[playerNumber]) {
		if (connector.egg.x == column) {
			[connector hitWithGarbage];
		}
	}
}

- (CGFloat)panForPlayerNumber:(int)playerNumber {
	return playerNumber == 0 ? -1.0 : 1.0;
}

- (void)loadSounds {
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"chain.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"dead.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"drop.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"garbage.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"garbagebig.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"land.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"lose.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"move.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"multichain1.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"multichain2.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"pause.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"rotate.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"win.wav"];
}

- (void)unloadSounds {
	[[SimpleAudioEngine sharedEngine] unloadEffect:@"chain.wav"];
	[[SimpleAudioEngine sharedEngine] unloadEffect:@"dead.wav"];
	[[SimpleAudioEngine sharedEngine] unloadEffect:@"drop.wav"];
	[[SimpleAudioEngine sharedEngine] unloadEffect:@"garbage.wav"];
	[[SimpleAudioEngine sharedEngine] unloadEffect:@"garbagebig.wav"];
	[[SimpleAudioEngine sharedEngine] unloadEffect:@"land.wav"];
	[[SimpleAudioEngine sharedEngine] unloadEffect:@"lose.wav"];
	[[SimpleAudioEngine sharedEngine] unloadEffect:@"move.wav"];
	[[SimpleAudioEngine sharedEngine] unloadEffect:@"multichain1.wav"];
	[[SimpleAudioEngine sharedEngine] unloadEffect:@"multichain2.wav"];
	[[SimpleAudioEngine sharedEngine] unloadEffect:@"pause.wav"];
	[[SimpleAudioEngine sharedEngine] unloadEffect:@"rotate.wav"];
	[[SimpleAudioEngine sharedEngine] unloadEffect:@"win.wav"];
}

- (void)prepareSpriteSheets {
	// Load sprite sheet definitions
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"red.plist"];
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"green.plist"];
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"blue.plist"];
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"yellow.plist"];
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"purple.plist"];
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"orange.plist"];
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"grey.plist"];
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"gridbottom.plist"];
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"gridbottomleft.plist"];
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"gridbottomright.plist"];
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"incoming.plist"];
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"message.plist"];
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"playertags.plist"];
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"orangenumbers.plist"];
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"purplenumbers.plist"];
	
	// Create sprite sheets from cached definitions
	_redEggSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"red.png"];
	_greenEggSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"green.png"];
	_blueEggSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"blue.png"];
	_yellowEggSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"yellow.png"];
	_orangeEggSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"orange.png"];
	_purpleEggSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"purple.png"];
	_garbageEggSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"grey.png"];
	_gridBottomEggSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"gridbottom.png"];
	_gridBottomLeftEggSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"gridbottomleft.png"];
	_gridBottomRightEggSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"gridbottomright.png"];
	_incomingSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"incoming.png"];
	_messageSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"message.png"];
	_playerTagSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"playertags.png"];
	_orangeNumberSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"orangenumbers.png"];
	_purpleNumberSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"purplenumbers.png"];
	
	// Disable anti-aliasing on all sprite sheets
	[_redEggSpriteSheet.texture setAliasTexParameters];
	[_greenEggSpriteSheet.texture setAliasTexParameters];
	[_blueEggSpriteSheet.texture setAliasTexParameters];
	[_yellowEggSpriteSheet.texture setAliasTexParameters];
	[_orangeEggSpriteSheet.texture setAliasTexParameters];
	[_purpleEggSpriteSheet.texture setAliasTexParameters];
	[_garbageEggSpriteSheet.texture setAliasTexParameters];
	[_gridBottomEggSpriteSheet.texture setAliasTexParameters];
	[_gridBottomLeftEggSpriteSheet.texture setAliasTexParameters];
	[_gridBottomRightEggSpriteSheet.texture setAliasTexParameters];
	[_incomingSpriteSheet.texture setAliasTexParameters];
	[_messageSpriteSheet.texture setAliasTexParameters];
	[_playerTagSpriteSheet.texture setAliasTexParameters];
	[_orangeNumberSpriteSheet.texture setAliasTexParameters];
	[_purpleNumberSpriteSheet.texture setAliasTexParameters];
	
	// Add sprite sheets to the layer
	[self addChild:_redEggSpriteSheet];
	[self addChild:_greenEggSpriteSheet];
	[self addChild:_blueEggSpriteSheet];
	[self addChild:_yellowEggSpriteSheet];
	[self addChild:_orangeEggSpriteSheet];
	[self addChild:_purpleEggSpriteSheet];
	[self addChild:_garbageEggSpriteSheet];
	[self addChild:_gridBottomEggSpriteSheet];
	[self addChild:_gridBottomLeftEggSpriteSheet];
	[self addChild:_gridBottomRightEggSpriteSheet];
	[self addChild:_incomingSpriteSheet];
	[self addChild:_messageSpriteSheet];
	[self addChild:_playerTagSpriteSheet];
	[self addChild:_orangeNumberSpriteSheet];
	[self addChild:_purpleNumberSpriteSheet];
}

- (void)loadBackground {
	int x = [[CCDirector sharedDirector] winSize].width / 2;
	int y = [[CCDirector sharedDirector] winSize].height / 2;

	CCSprite *playfield = [CCSprite spriteWithFile:@"playfield.png"];
	playfield.position = ccp(x, y);
	[playfield.texture setAliasTexParameters];
	[self addChild:playfield z:0];
}

- (void)runGameOverEffectState {

	// Work out who lost
	int loser = 0;
	
	if (_runners[1] != nil) {
		if (_runners[0].isDead && !_runners[1].isDead) {
			loser = 0;
		} else if (_runners[1].isDead && !_runners[0].isDead) {
			loser = 1;
		}
	}
	
	// Dribble sprites of loser off screen
	BOOL requiresIteration = NO;
	
	if (_deathEffectTimer % 8 == 0) {
		for (SZEggSpriteConnector *connector in _eggSpriteConnectors[loser]) {
			
			CCSprite *sprite = connector.sprite;
			SZEggBase *egg = connector.egg;
			
			// Don't drop the next egg sprites
			if (egg == [_runners[loser] nextEgg:0] || egg == [_runners[loser] nextEgg:1]) {
				continue;
			}
			
			// Drop the middle two columns first, then columns 1 and 4, then
			// the outer columns last.  Use the value of the timer to determine
			// which columns should be dropping
			if ((_deathEffectTimer > 0 && (egg.x == 2 || egg.x == 3)) ||
				(_deathEffectTimer > 8 && (egg.x == 1 || egg.x == 4)) ||
				(_deathEffectTimer > 16)) {
				sprite.position = ccp(sprite.position.x, sprite.position.y - (SZEggSize / 2));
			}
			
			// Need to keep iterating if any eggs are still on-screen
			if (sprite.position.y > -SZEggSize / 2) {
				requiresIteration = YES;
			}
		}
	} else {
		requiresIteration = YES;
	}
	
	if (!requiresIteration) {
		_state = SZGameStateGameOver;
		
		int requiredWins = ([SZSettings sharedSettings].gamesPerMatch / 2) + 1;
		
		if (loser == 0) {
			++_gameWins[1];
			
			if (_gameWins[1] == requiredWins) {
				
				// Player 2 wins this round
				[[SimpleAudioEngine sharedEngine] playEffect:@"lose.wav"];
				
				CCSprite *sprite = [CCSprite spriteWithSpriteFrameName:@"winner.png"];
				sprite.position = ccp(SZGrid2X + (sprite.contentSize.width / 2), ([[CCDirector sharedDirector] winSize].height - sprite.contentSize.height) / 2);
				[_messageSpriteSheet addChild:sprite];
				
				++_matchWins[1];
				_gameWins[0] = 0;
				_gameWins[1] = 0;
			}

			CCSprite *sprite = [CCSprite spriteWithSpriteFrameName:@"pressakey.png"];
			sprite.position = ccp(SZGrid1X + (sprite.contentSize.width / 2), ([[CCDirector sharedDirector] winSize].height - sprite.contentSize.height) / 2);
			[_messageSpriteSheet addChild:sprite];

		} else {
			++_gameWins[0];
			
			if (_gameWins[0] == requiredWins) {
				
				// Player 1 wins this round
				[[SimpleAudioEngine sharedEngine] playEffect:@"win.wav"];
				
				CCSprite *sprite = [CCSprite spriteWithSpriteFrameName:@"winner.png"];
				sprite.position = ccp(SZGrid1X + (sprite.contentSize.width / 2), ([[CCDirector sharedDirector] winSize].height - sprite.contentSize.height) / 2);
				[_messageSpriteSheet addChild:sprite];
				
				++_matchWins[0];
				_gameWins[0] = 0;
				_gameWins[1] = 0;
			}
			
			CCSprite *sprite = [CCSprite spriteWithSpriteFrameName:@"pressakey.png"];
			sprite.position = ccp(SZGrid2X + (sprite.contentSize.width / 2), ([[CCDirector sharedDirector] winSize].height - sprite.contentSize.height) / 2);
			[_messageSpriteSheet addChild:sprite];
		}

		[self createWinLabels];

		[[SZNetworkSession sharedSession] sendStartRound];
	}
	
	++_deathEffectTimer;
}

- (void)runEggWaitState {
	if ([SZSettings sharedSettings].gameType != SZGameTypeTwoPlayer) _state = SZGameStateActive;

	if ([[SZEggFactory sharedFactory] hasEggPairForPlayer:0] &&
		[[SZEggFactory sharedFactory] hasEggPairForPlayer:1]) _state = SZGameStateActive;
}

- (void)runRoundStartWaitState {
	if ([SZSettings sharedSettings].gameType != SZGameTypeTwoPlayer) _state = SZGameStateActive;

	if ([SZNetworkSession sharedSession].state == SZGameStateActive) {
		_state = SZGameStateActive;
	}
}

- (void)update:(ccTime)dt {
	
	// ccTime is measured in fractions of a second; we need it in frames per
	// second, using 60fps as the framerate
	int frames = (int)(round(2.0f * dt * SZFrameRate) / 2.0f);
	
	// Ensure that at least one frame will be processed
	if (frames == 0) frames = 1;
	
	for (int i = 0; i < frames; ++i) {
		
		switch (_state) {
			case SZGameStateActive:
				[self runActiveState];
				break;
				
			case SZGameStatePaused:
				[self runPausedState];
				break;
				
			case SZGameStateGameOverEffect:
				[self runGameOverEffectState];
				break;
				
			case SZGameStateGameOver:
				[self runGameOverState];
				break;

			case SZGameStateWaitingForEgg:
				[self runEggWaitState];
				break;

			case SZGameStateWaitingForRoundStart:
				[self runRoundStartWaitState];
				break;
		}
		
		[[SZPad instanceOne] update];
		[[SZPad instanceTwo] update];
	}
}

- (void)setEggsVisible:(BOOL)visible {
	for (int i = 0; i < SZMaximumPlayers; ++i) {

		if (_eggSpriteConnectors[i] == nil) continue;

		for (SZEggSpriteConnector *connector in _eggSpriteConnectors[i]) {
			if (connector.egg.y < SZGridHeight - 1) {
				[connector.sprite setVisible:visible];
			}
		}
	}
}

- (void)pauseGame {
	_state = SZGameStatePaused;
	
	[[SimpleAudioEngine sharedEngine] playEffect:@"pause.wav"];
	
	// Show "paused" message on both grids
	CCSprite *sprite = [CCSprite spriteWithSpriteFrameName:@"paused.png"];
	sprite.position = ccp(SZGrid1X + (sprite.contentSize.width / 2), ([[CCDirector sharedDirector] winSize].height - sprite.contentSize.height) / 2);
	[_messageSpriteSheet addChild:sprite];
	
	if (_runners[1] != nil) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"paused.png"];
		sprite.position = ccp(SZGrid2X + (sprite.contentSize.width / 2), ([[CCDirector sharedDirector] winSize].height - sprite.contentSize.height) / 2);
		[_messageSpriteSheet addChild:sprite];
	}
	
	[self setEggsVisible:NO];
}

- (void)resumeGame {
	_state = SZGameStateActive;

	// Remove all "paused" messages
	while ([[_messageSpriteSheet children] count] > 0) {
		[_messageSpriteSheet removeChildAtIndex:0 cleanup:YES];
	}

	[self setEggsVisible:YES];
}

- (void)createSpritesForNumber:(int)number colour:(NSString *)colour x:(int)x y:(int)y {

	CCSpriteBatchNode *sheet = _purpleNumberSpriteSheet;
	
	if ([colour isEqualToString:@"orange"]) {
		sheet = _orangeNumberSpriteSheet;
	}
	
	int digits = 0;
	
	if (digits > 0) digits = log10(number);
	
	do {
		NSString *spriteName = [NSString stringWithFormat:@"%@num%d.png", colour, number % 10];
		CCSprite *sprite = [CCSprite spriteWithSpriteFrameName:spriteName];
		[sheet addChild:sprite];
		
		// Offsetting the co-ords by 0.5 pixels apparently fixes the anti-
		// aliasing...
		sprite.position = ccp(x + 0.5 + (digits * sprite.boundingBox.size.width), y + 0.5);
		[sprite.texture setAliasTexParameters];
		
		--digits;
		number /= 10;
	} while (number > 0);
}

- (void)createWinLabels {
	
	// Practice games do not need labels
	if ([SZSettings sharedSettings].gameType == SZGameTypePractice) return;
	
	[_orangeNumberSpriteSheet removeAllChildrenWithCleanup:YES];
	[_purpleNumberSpriteSheet removeAllChildrenWithCleanup:YES];
	
	// Labels for player 1
	[self createSpritesForNumber:_matchWins[0] colour:@"orange" x:SZGrid1MatchScoreX y:SZGrid1ScoresY];
	[self createSpritesForNumber:_gameWins[0] colour:@"orange" x:SZGrid1GameScoreX y:SZGrid1ScoresY];
	
	// Labels for player 2
	[self createSpritesForNumber:_matchWins[1] colour:@"purple" x:SZGrid2MatchScoreX y:SZGrid2ScoresY];
	[self createSpritesForNumber:_gameWins[1] colour:@"purple" x:SZGrid2GameScoreX y:SZGrid2ScoresY];
}

- (void)resetGame {

	_state = SZGameStateActive;
	_deathEffectTimer = 0;

	[[SZPad instanceOne] reset];
	[[SZPad instanceTwo] reset];
	[[SZNetworkSession sharedSession] resetEggVotes];
	[[SZEggFactory sharedFactory] clear];

	// Release all existing game objects
	for (int i = 0; i < SZMaximumPlayers; ++i) {
		[_runners[i] release];
		_runners[i] = nil;

		[_eggSpriteConnectors[i] release];
		_eggSpriteConnectors[i] = nil;

		if (_incomingGarbageSprites[i] != nil) {
			for (CCSprite *sprite in _incomingGarbageSprites[i]) {
				[sprite removeFromParentAndCleanup:YES];
			}

			[_incomingGarbageSprites[i] release];

			_incomingGarbageSprites[i] = nil;
		}
	}
	
	[_messageSpriteSheet removeAllChildrenWithCleanup:YES];
	[_gridBottomEggSpriteSheet removeAllChildrenWithCleanup:YES];
	[_playerTagSpriteSheet removeAllChildrenWithCleanup:YES];

	// Create new game objects
	int players = [SZSettings sharedSettings].gameType == SZGameTypePractice ? 1 : 2;
	
	_eggSpriteConnectors[0] = [[NSMutableArray alloc] init];
	_incomingGarbageSprites[0] = [[NSMutableArray alloc] init];

	SZGrid *grid = [[SZGrid alloc] initWithPlayerNumber:0];
	grid.delegate = self;
	
	id <SZGameController> controller = [[SZPlayerOneController alloc] init];
	
	_runners[0] = [[SZGridRunner alloc] initWithController:controller
													  grid:grid
											  playerNumber:0
													 speed:[SZSettings sharedSettings].speed
												  isRemote:NO];
	_runners[0].delegate = self;
	
	[grid release];
	[controller release];

	if (players > 1) {
		_eggSpriteConnectors[1] = [[NSMutableArray alloc] init];
		_incomingGarbageSprites[1] = [[NSMutableArray alloc] init];

		grid = [[SZGrid alloc] initWithPlayerNumber:1];
		grid.delegate = self;
		
		if ([SZSettings sharedSettings].gameType == SZGameTypeSinglePlayer) {
			controller = [[SZSmartAIController alloc] initWithHesitation:(int)([SZSettings sharedSettings].aiType) grid:grid];
		} else {
			controller = [[SZPlayerTwoController alloc] init];
		}
		
		_runners[1] = [[SZGridRunner alloc] initWithController:controller
														  grid:grid
												  playerNumber:1
														 speed:[SZSettings sharedSettings].speed
													  isRemote:[SZSettings sharedSettings].gameType == SZGameTypeTwoPlayer];
		_runners[1].delegate = self;

		[grid release];
		[controller release];
	}

	[_runners[0].grid createBottomRow];
	[_runners[0].grid addGarbage:SZGridWidth * [SZSettings sharedSettings].height randomPlacement:[SZSettings sharedSettings].gameType == SZGameTypeTwoPlayer];

	if (_runners[1] != nil) {
		[_runners[1].grid createBottomRow];
		[_runners[1].grid addGarbage:SZGridWidth * [SZSettings sharedSettings].height randomPlacement:[SZSettings sharedSettings].gameType == SZGameTypeTwoPlayer];
	}
	
	if ([SZSettings sharedSettings].gameType == SZGameTypePractice) {
		[self blankSecondGrid];
	} else {
		// Add CPU tag to second grid
		CCSprite *sprite = [CCSprite spriteWithSpriteFrameName:@"cpu.png"];
		sprite.position = ccp(SZGrid2TagX + 0.5, SZGrid2TagY + 0.5);
		[_playerTagSpriteSheet addChild:sprite];
	}
}

- (void)blankSecondGrid {
	CCSpriteBatchNode *sheet = _gridBottomEggSpriteSheet;
	CCSprite *sprite;
	
	for (int y = 0; y < SZGridHeight; ++y) {
		for (int x = 0; x < SZGridWidth; ++x) {
			sprite = [CCSprite spriteWithSpriteFrameName:@"gridbottom00.png"];
			
			sprite.position = ccp((x * SZEggSize) + SZGrid2X + 24, (y * SZEggSize) + 24);
			
			[sheet addChild:sprite];
		}
	}
}

- (void)runGameOverState {
	
	[[SZNetworkSession sharedSession] resetEggVotes];
	[[SZEggFactory sharedFactory] clear];
	
	if ([[SZPad instanceOne] isStartNewPress] ||
		[[SZPad instanceOne] isANewPress] ||
		[[SZPad instanceOne] isBNewPress] ||
		[[SZPad instanceOne] isLeftNewPress] ||
		[[SZPad instanceOne] isRightNewPress] ||
		[[SZPad instanceTwo] isStartNewPress] ||
		[[SZPad instanceTwo] isANewPress] ||
		[[SZPad instanceTwo] isBNewPress] ||
		[[SZPad instanceTwo] isLeftNewPress] ||
		[[SZPad instanceTwo] isRightNewPress]) {
		[self resetGame];
	}
}

- (void)runPausedState {
	if ([[SZPad instanceOne] isStartNewPress] || [[SZPad instanceTwo] isStartNewPress]) {
		[self resumeGame];
	}
	
	[[SZPad instanceOne] releaseStart];
	[[SZPad instanceTwo] releaseStart];
}

- (void)runActiveState {
	
	// Check for pause mode request
	if ([[SZPad instanceOne] isStartNewPress] || [[SZPad instanceTwo] isStartNewPress]) {
		[self pauseGame];
		return;
	}
	
	if (_runners[0].grid.hasLiveEggs) {
		SZEggBase *egg = [_runners[0].grid liveEgg:0];
		
		if (_columnTarget > -1) {
			if (egg.x < _columnTarget) {
				[[SZPad instanceOne] pressRight];
			} else if (egg.x > _columnTarget) {
				[[SZPad instanceOne] pressLeft];
			}
		}
	} else {
		_columnTarget = -1;
	}
	
	for (int i = 0; i < SZMaximumPlayers; ++i) {
		[_runners[i] iterate];
	}
	
	[[SZPad instanceOne] releaseLeft];
	[[SZPad instanceOne] releaseRight];
	[[SZPad instanceOne] releaseA];
	[[SZPad instanceOne] releaseB];
	
	if (_runners[1] == nil) {

		// Practice game
		if (_runners[0].isDead) {
			
			// Single player dead
			[[SimpleAudioEngine sharedEngine] playEffect:@"dead.wav"];
			_state = SZGameStateGameOverEffect;
			_deathEffectTimer = 0;
		}
	} else {

		// Two-player game
		if (_runners[0].isDead && !_runners[1].isDead) {
			
			// Player one dead
			[[SimpleAudioEngine sharedEngine] playEffect:@"dead.wav"];

			_state = SZGameStateGameOverEffect;
			_deathEffectTimer = 0;
			
		} else if (_runners[1].isDead && !_runners[0].isDead) {
			
			// Player two dead
			[[SimpleAudioEngine sharedEngine] playEffect:@"dead.wav"];
			
			_state = SZGameStateGameOverEffect;
			_deathEffectTimer = 0;
			
		} else if (_runners[1].isDead && _runners[0].isDead) {
			
			// Both dead
			[[SimpleAudioEngine sharedEngine] playEffect:@"dead.wav"];
			
			_state = SZGameStateGameOverEffect;
			_deathEffectTimer = 0;
		}
		
		// Move garbage from one runner to the other
		if ([_runners[0] addIncomingGarbage:_runners[1].outgoingGarbageCount]) {
			[_runners[1] clearOutgoingGarbageCount];
			
			[self updateIncomingGarbageDisplayForRunner:_runners[0]];
		}
		
		if ([_runners[1] addIncomingGarbage:_runners[0].outgoingGarbageCount]) {
			[_runners[0] clearOutgoingGarbageCount];
			
			[self updateIncomingGarbageDisplayForRunner:_runners[1]];
		}
	}
		
	[self updateEggSpriteConnectors];
}

- (void)updateEggSpriteConnectors {
	
	for (int j = 0; j < SZMaximumPlayers; ++j) {

		if (_eggSpriteConnectors[j] == nil) continue;

		for (int i = 0; i < [_eggSpriteConnectors[j] count]; ++i) {
			if (((SZEggSpriteConnector *)[_eggSpriteConnectors[j] objectAtIndex:i]).isDead) {
				[_eggSpriteConnectors[j] removeObjectAtIndex:i];
				--i;
			} else {
				[[_eggSpriteConnectors[j] objectAtIndex:i] update];
			}
		}
	}
}

- (void)updateIncomingGarbageDisplayForRunner:(SZGridRunner *)runner {
	
	int playerNumber = runner.playerNumber;
	
	// Remove existing boulders
	for (int i = 0; i < [_incomingGarbageSprites[playerNumber] count]; ++i) {
		[_incomingSpriteSheet removeChild:[_incomingGarbageSprites[playerNumber] objectAtIndex:i] cleanup:YES];
	}
	
	[_incomingGarbageSprites[playerNumber] removeAllObjects];
	
	int garbage = _runners[playerNumber].incomingGarbageCount;
	
	if (garbage == 0) return;
	
	int faceBoulders = garbage / SZGarbageFaceBoulderValue;
	garbage -= faceBoulders * SZGarbageFaceBoulderValue;
	
	int largeBoulders = garbage / SZGarbageLargeBoulderValue;
	garbage -= largeBoulders * SZGarbageLargeBoulderValue;
	
	int spriteY = [[CCDirector sharedDirector] winSize].height - 1;
	int spriteX = playerNumber == 0 ? 0 : [[CCDirector sharedDirector] winSize].width - SZEggSize;
	
	for (int i = 0; i < faceBoulders; ++i) {
		CCSprite *boulder = [CCSprite spriteWithSpriteFrameName:@"incoming2.png"];
		boulder.position = ccp(spriteX + (SZEggSize / 2), spriteY - ([boulder contentSize].height / 2));
		[_incomingSpriteSheet addChild:boulder];
		
		spriteY -= [boulder contentSize].height + 1;
		
		[_incomingGarbageSprites[playerNumber] addObject:boulder];
	}
	
	for (int i = 0; i < largeBoulders; ++i) {
		CCSprite *boulder = [CCSprite spriteWithSpriteFrameName:@"incoming1.png"];
		boulder.position = ccp(spriteX + (SZEggSize / 2), spriteY - ([boulder contentSize].height / 2));
		[_incomingSpriteSheet addChild:boulder];
		
		spriteY -= [boulder contentSize].height + 1;
		
		[_incomingGarbageSprites[playerNumber] addObject:boulder];
	}
	
	for (int i = 0; i < garbage; ++i) {
		CCSprite *boulder = [CCSprite spriteWithSpriteFrameName:@"incoming0.png"];
		boulder.position = ccp(spriteX + (SZEggSize / 2), spriteY - ([boulder contentSize].height / 2));
		[_incomingSpriteSheet addChild:boulder];
		
		spriteY -= [boulder contentSize].height + 1;
		
		[_incomingGarbageSprites[playerNumber] addObject:boulder];
	}
}

- (void)dealloc {
	
	[self unloadSounds];
	
	for (int i = 0; i < SZMaximumPlayers; ++i) {
		[_runners[i] release];
		[_eggSpriteConnectors[i] release];
		[_incomingGarbageSprites[i] release];
	}
	
	[super dealloc];
}

- (void)createEggSpriteConnector:(SZEggBase *)egg gridX:(int)gridX gridY:(int)gridY connectorArray:(NSMutableArray *)connectorArray {
	
	CCSprite *sprite = nil;
	CCSpriteBatchNode *sheet = nil;
	
	if ([egg isKindOfClass:[SZRedEgg class]]) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"red00.png"];
		sheet = _redEggSpriteSheet;
	} else if ([egg isKindOfClass:[SZGreenEgg class]]) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"green00.png"];
		sheet = _greenEggSpriteSheet;
	} else if ([egg isKindOfClass:[SZBlueEgg class]]) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"blue00.png"];
		sheet = _blueEggSpriteSheet;
	} else if ([egg isKindOfClass:[SZYellowEgg class]]) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"yellow00.png"];
		sheet = _yellowEggSpriteSheet;
	} else if ([egg isKindOfClass:[SZOrangeEgg class]]) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"orange00.png"];
		sheet = _orangeEggSpriteSheet;
	} else if ([egg isKindOfClass:[SZPurpleEgg class]]) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"purple00.png"];
		sheet = _purpleEggSpriteSheet;
	} else if ([egg isKindOfClass:[SZGarbageEgg class]]) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"grey00.png"];
		sheet = _garbageEggSpriteSheet;
	} else if ([egg isKindOfClass:[SZGridBottomEgg class]]) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"gridbottom00.png"];
		sheet = _gridBottomEggSpriteSheet;
	} else if ([egg isKindOfClass:[SZGridBottomLeftEgg class]]) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"gridbottomleft00.png"];
		sheet = _gridBottomLeftEggSpriteSheet;
	} else if ([egg isKindOfClass:[SZGridBottomRightEgg class]]) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"gridbottomright00.png"];
		sheet = _gridBottomRightEggSpriteSheet;
	}
	
	// Connect the sprite and egg together
	SZEggSpriteConnector *connector = [[SZEggSpriteConnector alloc] initWithEgg:egg sprite:sprite gridX:gridX gridY:gridY];
	[connectorArray addObject:connector];
	[connector release];
	
	[sheet addChild:sprite];
}

#pragma mark - SZGridDelegate

- (void)didAddGarbageEggRowToGrid:(SZGrid *)grid {
	CGFloat pan = [self panForPlayerNumber:grid.playerNumber];
	[[SimpleAudioEngine sharedEngine] playEffect:@"garbagebig.wav" pitch:1.0 pan:pan gain:1.0];
}

- (void)didLandEggInGrid:(SZGrid *)grid {
	CGFloat pan = [self panForPlayerNumber:grid.playerNumber];
	[[SimpleAudioEngine sharedEngine] playEffect:@"land.wav" pitch:1.0 pan:pan gain:1.0];
}

- (void)didLandGarbageEggInGrid:(SZGrid *)grid {
	CGFloat pan = [self panForPlayerNumber:grid.playerNumber];
	[[SimpleAudioEngine sharedEngine] playEffect:@"garbage.wav" pitch:1.0 pan:pan gain:1.0];
}

- (void)grid:(SZGrid *)grid didAddEgg:(SZEggBase *)egg {
	if (![self moveNextEggToGridForPlayer:grid.playerNumber egg:egg]) {

		// No existing next egg exists (this must be a garbage egg) so create
		// the connector
		[self addEggSpriteConnectorForPlayer:grid.playerNumber egg:egg];
	}
}

- (void)grid:(SZGrid *)grid didLandGarbageEgg:(SZEggBase *)egg {

	// Offsets all of the eggs in the column so that the column appears to
	// squash under the garbage weight.
	[self hitColumnWithGarbageForPlayerNumber:grid.playerNumber column:egg.x];
}

#pragma mark - SZGridRunnerDelegate

- (void)didGridRunnerAddLiveEggs:(SZGridRunner *)gridRunner {

}

- (void)didGridRunnerClearIncomingGarbage:(SZGridRunner *)gridRunner {
	[self updateIncomingGarbageDisplayForRunner:gridRunner];
}

- (void)didGridRunnerCreateNextEggs:(SZGridRunner *)gridRunner {
	[self createNextEggSpriteConnectorPairForRunner:gridRunner];

	if (gridRunner.playerNumber == 0) {
		[[SZPad instanceOne] releaseDown];
		_didDrag = NO;
		_columnTarget = -1;
		_dragStartColumn = -1;
		_dragStartX = -1;
	}
}

- (void)didGridRunnerExplodeChain:(SZGridRunner *)gridRunner sequence:(int)sequence {
	CGFloat pan = [self panForPlayerNumber:gridRunner.playerNumber];
	[[SimpleAudioEngine sharedEngine] playEffect:@"chain.wav" pitch:(1.0 + (sequence * 0.05)) pan:pan gain:1.0];
}

- (void)didGridRunnerExplodeMultipleChains:(SZGridRunner *)gridRunner {
	NSString *filename = gridRunner.playerNumber == 0 ? @"multichain1.wav" : @"multichain2.wav";
	CGFloat pan = [self panForPlayerNumber:gridRunner.playerNumber];
	[[SimpleAudioEngine sharedEngine] playEffect:filename pitch:1.0 pan:pan gain:1.0];
}

- (void)didGridRunnerMoveLiveEggs:(SZGridRunner *)gridRunner {
	CGFloat pan = [self panForPlayerNumber:gridRunner.playerNumber];
	[[SimpleAudioEngine sharedEngine] playEffect:@"move.wav" pitch:1.0 pan:pan gain:1.0];
}

- (void)didGridRunnerRotateLiveEggs:(SZGridRunner *)gridRunner {
	CGFloat pan = [self panForPlayerNumber:gridRunner.playerNumber];
	[[SimpleAudioEngine sharedEngine] playEffect:@"rotate.wav" pitch:1.0 pan:pan gain:1.0];
}

- (void)didGridRunnerStartDroppingLiveEggs:(SZGridRunner *)gridRunner {

	int players = [SZSettings sharedSettings].gameType == SZGameTypePractice ? 1 : 2;

	CGFloat pan = [self panForPlayerNumber:gridRunner.playerNumber];

	// Never play the drop sound for the AI player as it is irritating.
	if (gridRunner.playerNumber == 0 || (gridRunner.playerNumber == 1 && players == 1)) {
		[[SimpleAudioEngine sharedEngine] playEffect:@"drop.wav" pitch:1.0 pan:pan gain:1.0];
	}
}

@end
