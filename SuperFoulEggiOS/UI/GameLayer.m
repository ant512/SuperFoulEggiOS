#import <Foundation/Foundation.h>

#import "cocos2d.h"
#import "SimpleAudioEngine.h"
#import "CDAudioManager.h"
#import "CocosDenshion.h"

#import "GameLayer.h"
#import "SZPlayerOneController.h"
#import "SZPad.h"
#import "SZPoint.h"

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
#import "Settings.h"

#import "GameTypeMenuLayer.h"

#import "CCNode+SFGestureRecognizers.h"

@implementation GameLayer

+ (CCScene *)scene {
	
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	GameLayer *layer = [GameLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

- (id)init {
	if ((self = [super init])) {
		
		sranddev();
		
		self.touchEnabled = YES;
		
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
		
		int players = [Settings sharedSettings].gameType == GamePracticeType ? 1 : 2;
		
		_eggFactory = [[SZEggFactory alloc] initWithPlayerCount:players eggColourCount:[Settings sharedSettings].blockColours];
		
		// TODO: Are these pointers already equal to nil?
		for (int i = 0; i < MAX_PLAYERS; ++i) {
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
	
	[[SZPad instanceTwo] pressA];
	_columnTarget = -1;
	
	_didDrag = NO;
	_dragStartColumn = -1;
	_dragStartX = -1;
}

- (void)handleAntiClockwiseRotateTap:(UITapGestureRecognizer *)gesture {
	
	if (_didDrag) return;
	
	[[SZPad instanceTwo] pressB];
	_columnTarget = -1;
	
	_didDrag = NO;
	_dragStartColumn = -1;
	_dragStartX = -1;
}

- (void)handleDropSwipe:(UISwipeGestureRecognizer *)gesture {
	
	if(_didDrag) return;
	
	[[SZPad instanceTwo] pressDown];
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

	int block1X = [[_runners[0].grid liveEgg:0] x];
	int block2X = [[_runners[0].grid liveEgg:1] x];

	// Remember the left-most column.  We'll drag relative to this.
	_dragStartColumn = block1X < block2X ? block1X : block2X;
	_dragStartX = point.x;
}

- (void)dragMoved:(CGPoint)point {
	
	if (_dragStartColumn == -1) return;
	
	int newColumnTarget = _dragStartColumn + ((point.x - _dragStartX) / BLOCK_SIZE);

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

- (void)createNextBlockSpriteConnectorPairForRunner:(GridRunner*)runner {

	int gridX = runner.playerNumber == 0 ? NEXT_BLOCK_1_X : NEXT_BLOCK_2_X;
	
	NSMutableArray* connectorArray = _blockSpriteConnectors[runner.playerNumber];
	
	// Create a new sprite for both next blocks
	for (int i = 0; i < 2; ++i) {
		[self createBlockSpriteConnector:[runner nextBlock:i] gridX:gridX gridY:NEXT_BLOCK_Y connectorArray:connectorArray];
		gridX += BLOCK_SIZE;
	}
}

- (BOOL)moveNextBlockToGridForPlayer:(int)playerNumber block:(SZEggBase*)block {
	int gridX = playerNumber == 0 ? GRID_1_X : GRID_2_X;
	
	NSMutableArray* connectorArray = _blockSpriteConnectors[playerNumber];
	
	// If there is already a connector for this block, we need to adjust
	// its grid co-ordinates back to the real values.  At present the
	// co-ords are being abused to make the sprite appear in the "next
	// block" location
	for (SZEggSpriteConnector* connector in connectorArray) {
		if (connector.egg == block) {
			connector.gridX = gridX;
			connector.gridY = GRID_Y;
			
			[connector updateSpritePosition];
			
			return YES;
		}
	}

	// No existing block exists (this must be a garbage block)
	return NO;
}

- (void)addBlockSpriteConnectorForPlayer:(int)playerNumber block:(SZEggBase*)block {
	int gridX = playerNumber == 0 ? GRID_1_X : GRID_2_X;
	
	NSMutableArray* connectorArray = _blockSpriteConnectors[playerNumber];

	[self createBlockSpriteConnector:block gridX:gridX gridY:GRID_Y connectorArray:connectorArray];
}

- (void)hitColumnWithGarbageForPlayerNumber:(int)playerNumber column:(int)column {
	for (SZEggSpriteConnector* connector in _blockSpriteConnectors[playerNumber]) {
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
	_redBlockSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"red.png"];
	_greenBlockSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"green.png"];
	_blueBlockSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"blue.png"];
	_yellowBlockSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"yellow.png"];
	_orangeBlockSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"orange.png"];
	_purpleBlockSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"purple.png"];
	_garbageBlockSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"grey.png"];
	_gridBottomBlockSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"gridbottom.png"];
	_gridBottomLeftBlockSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"gridbottomleft.png"];
	_gridBottomRightBlockSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"gridbottomright.png"];
	_incomingSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"incoming.png"];
	_messageSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"message.png"];
	_playerTagSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"playertags.png"];
	_orangeNumberSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"orangenumbers.png"];
	_purpleNumberSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"purplenumbers.png"];
	
	// Disable anti-aliasing on all sprite sheets
	[_redBlockSpriteSheet.texture setAliasTexParameters];
	[_greenBlockSpriteSheet.texture setAliasTexParameters];
	[_blueBlockSpriteSheet.texture setAliasTexParameters];
	[_yellowBlockSpriteSheet.texture setAliasTexParameters];
	[_orangeBlockSpriteSheet.texture setAliasTexParameters];
	[_purpleBlockSpriteSheet.texture setAliasTexParameters];
	[_garbageBlockSpriteSheet.texture setAliasTexParameters];
	[_gridBottomBlockSpriteSheet.texture setAliasTexParameters];
	[_gridBottomLeftBlockSpriteSheet.texture setAliasTexParameters];
	[_gridBottomRightBlockSpriteSheet.texture setAliasTexParameters];
	[_incomingSpriteSheet.texture setAliasTexParameters];
	[_messageSpriteSheet.texture setAliasTexParameters];
	[_playerTagSpriteSheet.texture setAliasTexParameters];
	[_orangeNumberSpriteSheet.texture setAliasTexParameters];
	[_purpleNumberSpriteSheet.texture setAliasTexParameters];
	
	// Add sprite sheets to the layer
	[self addChild:_redBlockSpriteSheet];
	[self addChild:_greenBlockSpriteSheet];
	[self addChild:_blueBlockSpriteSheet];
	[self addChild:_yellowBlockSpriteSheet];
	[self addChild:_orangeBlockSpriteSheet];
	[self addChild:_purpleBlockSpriteSheet];
	[self addChild:_garbageBlockSpriteSheet];
	[self addChild:_gridBottomBlockSpriteSheet];
	[self addChild:_gridBottomLeftBlockSpriteSheet];
	[self addChild:_gridBottomRightBlockSpriteSheet];
	[self addChild:_incomingSpriteSheet];
	[self addChild:_messageSpriteSheet];
	[self addChild:_playerTagSpriteSheet];
	[self addChild:_orangeNumberSpriteSheet];
	[self addChild:_purpleNumberSpriteSheet];
}

- (void)loadBackground {
	int x = [[CCDirector sharedDirector] winSize].width / 2;
	int y = [[CCDirector sharedDirector] winSize].height / 2;

	CCSprite* playfield = [CCSprite spriteWithFile:@"playfield.png"];
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
		for (SZEggSpriteConnector* connector in _blockSpriteConnectors[loser]) {
			
			CCSprite* sprite = connector.sprite;
			SZEggBase* block = connector.egg;
			
			// Don't drop the next block sprites
			if (block == [_runners[loser] nextBlock:0] || block == [_runners[loser] nextBlock:1]) {
				continue;
			}
			
			// Drop the middle two columns first, then columns 1 and 4, then
			// the outer columns last.  Use the value of the timer to determine
			// which columns should be dropping
			if ((_deathEffectTimer > 0 && (block.x == 2 || block.x == 3)) ||
				(_deathEffectTimer > 8 && (block.x == 1 || block.x == 4)) ||
				(_deathEffectTimer > 16)) {
				sprite.position = ccp(sprite.position.x, sprite.position.y - (BLOCK_SIZE / 2));
			}
			
			// Need to keep iterating if any blocks are still on-screen
			if (sprite.position.y > -BLOCK_SIZE / 2) {
				requiresIteration = YES;
			}
		}
	} else {
		requiresIteration = YES;
	}
	
	if (!requiresIteration) {
		_state = SZGameStateGameOver;
		
		int requiredWins = ([Settings sharedSettings].gamesPerMatch / 2) + 1;
		
		if (loser == 0) {
			++_gameWins[1];
			
			if (_gameWins[1] == requiredWins) {
				
				// Player 2 wins this round
				[[SimpleAudioEngine sharedEngine] playEffect:@"lose.wav"];
				
				CCSprite* sprite = [CCSprite spriteWithSpriteFrameName:@"winner.png"];
				sprite.position = ccp(GRID_2_X + (sprite.contentSize.width / 2), ([[CCDirector sharedDirector] winSize].height - sprite.contentSize.height) / 2);
				[_messageSpriteSheet addChild:sprite];
				
				++_matchWins[1];
				_gameWins[0] = 0;
				_gameWins[1] = 0;
			}

			CCSprite* sprite = [CCSprite spriteWithSpriteFrameName:@"pressakey.png"];
			sprite.position = ccp(GRID_1_X + (sprite.contentSize.width / 2), ([[CCDirector sharedDirector] winSize].height - sprite.contentSize.height) / 2);
			[_messageSpriteSheet addChild:sprite];

		} else {
			++_gameWins[0];
			
			if (_gameWins[0] == requiredWins) {
				
				// Player 1 wins this round
				[[SimpleAudioEngine sharedEngine] playEffect:@"win.wav"];
				
				CCSprite* sprite = [CCSprite spriteWithSpriteFrameName:@"winner.png"];
				sprite.position = ccp(GRID_1_X + (sprite.contentSize.width / 2), ([[CCDirector sharedDirector] winSize].height - sprite.contentSize.height) / 2);
				[_messageSpriteSheet addChild:sprite];
				
				++_matchWins[0];
				_gameWins[0] = 0;
				_gameWins[1] = 0;
			}
			
			CCSprite* sprite = [CCSprite spriteWithSpriteFrameName:@"pressakey.png"];
			sprite.position = ccp(GRID_2_X + (sprite.contentSize.width / 2), ([[CCDirector sharedDirector] winSize].height - sprite.contentSize.height) / 2);
			[_messageSpriteSheet addChild:sprite];
		}

		[self createWinLabels];
	}
	
	++_deathEffectTimer;
}

- (void)update:(ccTime)dt {
	
	// ccTime is measured in fractions of a second; we need it in frames per
	// second, using 60fps as the framerate
	int frames = (int)(round(2.0f * dt * FRAME_RATE) / 2.0f);
	
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
		}
		
		[[SZPad instanceOne] update];
		[[SZPad instanceTwo] update];
	}
}

- (void)setBlocksVisible:(BOOL)visible {
	for (int i = 0; i < MAX_PLAYERS; ++i) {

		if (_blockSpriteConnectors[i] == nil) continue;

		for (SZEggSpriteConnector* connector in _blockSpriteConnectors[i]) {
			if (connector.egg.y < GRID_HEIGHT - 1) {
				[connector.sprite setVisible:visible];
			}
		}
	}
}

- (void)pauseGame {
	_state = SZGameStatePaused;
	
	[[SimpleAudioEngine sharedEngine] playEffect:@"pause.wav"];
	
	// Show "paused" message on both grids
	CCSprite* sprite = [CCSprite spriteWithSpriteFrameName:@"paused.png"];
	sprite.position = ccp(GRID_1_X + (sprite.contentSize.width / 2), ([[CCDirector sharedDirector] winSize].height - sprite.contentSize.height) / 2);
	[_messageSpriteSheet addChild:sprite];
	
	if (_runners[1] != nil) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"paused.png"];
		sprite.position = ccp(GRID_2_X + (sprite.contentSize.width / 2), ([[CCDirector sharedDirector] winSize].height - sprite.contentSize.height) / 2);
		[_messageSpriteSheet addChild:sprite];
	}
	
	[self setBlocksVisible:NO];
}

- (void)resumeGame {
	_state = SZGameStateActive;

	// Remove all "paused" messages
	while ([[_messageSpriteSheet children] count] > 0) {
		[_messageSpriteSheet removeChildAtIndex:0 cleanup:YES];
	}

	[self setBlocksVisible:YES];
}

- (void)createSpritesForNumber:(int)number colour:(NSString*)colour x:(int)x y:(int)y {

	CCSpriteBatchNode* sheet = _purpleNumberSpriteSheet;
	
	if ([colour isEqualToString:@"orange"]) {
		sheet = _orangeNumberSpriteSheet;
	}
	
	int digits = 0;
	
	if (digits > 0) digits = log10(number);
	
	do {
		NSString* spriteName = [NSString stringWithFormat:@"%@num%d.png", colour, number % 10];
		CCSprite* sprite = [CCSprite spriteWithSpriteFrameName:spriteName];
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
	if ([Settings sharedSettings].gameType == GamePracticeType) return;
	
	[_orangeNumberSpriteSheet removeAllChildrenWithCleanup:YES];
	[_purpleNumberSpriteSheet removeAllChildrenWithCleanup:YES];
	
	// Labels for player 1
	[self createSpritesForNumber:_matchWins[0] colour:@"orange" x:GRID_1_MATCH_SCORE_X y:GRID_1_SCORES_Y];
	[self createSpritesForNumber:_gameWins[0] colour:@"orange" x:GRID_1_GAME_SCORE_X y:GRID_1_SCORES_Y];
	
	// Labels for player 2
	[self createSpritesForNumber:_matchWins[1] colour:@"purple" x:GRID_2_MATCH_SCORE_X y:GRID_2_SCORES_Y];
	[self createSpritesForNumber:_gameWins[1] colour:@"purple" x:GRID_2_GAME_SCORE_X y:GRID_2_SCORES_Y];
}

- (void)resetGame {

	_state = SZGameStateActive;
	_deathEffectTimer = 0;

	[[SZPad instanceOne] reset];
	[[SZPad instanceTwo] reset];
	[_eggFactory clear];

	// Release all existing game objects
	for (int i = 0; i < MAX_PLAYERS; ++i) {
		[_runners[i] release];
		_runners[i] = nil;

		[_blockSpriteConnectors[i] release];
		_blockSpriteConnectors[i] = nil;

		if (_incomingGarbageSprites[i] != nil) {
			for (CCSprite* sprite in _incomingGarbageSprites[i]) {
				[sprite removeFromParentAndCleanup:YES];
			}

			[_incomingGarbageSprites[i] release];

			_incomingGarbageSprites[i] = nil;
		}
	}
	
	[_messageSpriteSheet removeAllChildrenWithCleanup:YES];
	[_gridBottomBlockSpriteSheet removeAllChildrenWithCleanup:YES];
	[_playerTagSpriteSheet removeAllChildrenWithCleanup:YES];

	// Create new game objects
	int players = [Settings sharedSettings].gameType == GamePracticeType ? 1 : 2;
	
	_blockSpriteConnectors[0] = [[NSMutableArray alloc] init];
	_incomingGarbageSprites[0] = [[NSMutableArray alloc] init];

	SZGrid* grid = [[SZGrid alloc] initWithPlayerNumber:0];
	grid.delegate = self;
	
	id <SZGameController> controller;
	
	// Use the second player control layout in a single-player game, as they
	// are slightly more intuitive than the first player controls
	if ([Settings sharedSettings].gameType == GameTwoPlayerType) {
		controller = [[SZPlayerOneController alloc] init];
	} else {
		controller = [[SZPlayerTwoController alloc] init];
	}
	
	_runners[0] = [[GridRunner alloc] initWithController:controller
													grid:grid
											  eggFactory:_eggFactory
											playerNumber:0
												   speed:[Settings sharedSettings].speed];
	_runners[0].delegate = self;
	
	[grid release];
	[controller release];

	if (players > 1) {
		_blockSpriteConnectors[1] = [[NSMutableArray alloc] init];
		_incomingGarbageSprites[1] = [[NSMutableArray alloc] init];

		grid = [[SZGrid alloc] initWithPlayerNumber:1];
		grid.delegate = self;
		
		if ([Settings sharedSettings].gameType == GameSinglePlayerType) {
			controller = [[SmartAIController alloc] initWithHesitation:(int)([Settings sharedSettings].aiType) grid:grid];
		} else {
			controller = [[SZPlayerTwoController alloc] init];
		}
		
		_runners[1] = [[GridRunner alloc] initWithController:controller
														grid:grid
												  eggFactory:_eggFactory
												playerNumber:1
													   speed:[Settings sharedSettings].speed];
		_runners[1].delegate = self;

		[grid release];
		[controller release];
	}

	[_runners[0].grid createBottomRow];
	[_runners[0].grid addGarbage:GRID_WIDTH * [Settings sharedSettings].height];

	if (_runners[1] != nil) {
		[_runners[1].grid createBottomRow];
		[_runners[1].grid addGarbage:GRID_WIDTH * [Settings sharedSettings].height];
	}
	
	if ([Settings sharedSettings].gameType == GamePracticeType) {
		[self blankSecondGrid];
	} else {
		// Add CPU tag to second grid
		CCSprite* sprite = [CCSprite spriteWithSpriteFrameName:@"cpu.png"];
		sprite.position = ccp(GRID_2_TAG_X + 0.5, GRID_2_TAG_Y + 0.5);
		[_playerTagSpriteSheet addChild:sprite];
	}
}

- (void)blankSecondGrid {
	CCSpriteBatchNode* sheet = _gridBottomBlockSpriteSheet;
	CCSprite* sprite;
	
	for (int y = 0; y < GRID_HEIGHT; ++y) {
		for (int x = 0; x < GRID_WIDTH; ++x) {
			sprite = [CCSprite spriteWithSpriteFrameName:@"gridbottom00.png"];
			
			sprite.position = ccp((x * BLOCK_SIZE) + GRID_2_X + 24, (y * BLOCK_SIZE) + 24);
			
			[sheet addChild:sprite];
		}
	}
}

- (void)runGameOverState {
	if ([[SZPad instanceOne] isStartNewPress] ||
		[[SZPad instanceOne] isANewPress] ||
		[[SZPad instanceOne] isBNewPress] ||
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
}

- (void)runActiveState {
	
	// Check for pause mode request
	if ([[SZPad instanceOne] isStartNewPress] || [[SZPad instanceTwo] isStartNewPress]) {
		[self pauseGame];
		return;
	}
	
	if (_runners[0].grid.hasLiveEggs) {
		SZEggBase *block = [_runners[0].grid liveEgg:0];
		
		if (_columnTarget > -1) {
			if (block.x < _columnTarget) {
				[[SZPad instanceTwo] pressRight];
			} else if (block.x > _columnTarget) {
				[[SZPad instanceTwo] pressLeft];
			}
		}
	} else {
		_columnTarget = -1;
	}
	
	for (int i = 0; i < MAX_PLAYERS; ++i) {
		[_runners[i] iterate];
	}
	
	[[SZPad instanceTwo] releaseLeft];
	[[SZPad instanceTwo] releaseRight];
	[[SZPad instanceTwo] releaseA];
	[[SZPad instanceTwo] releaseB];
	
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
		
	[self updateBlockSpriteConnectors];
}

- (void)updateBlockSpriteConnectors {
	
	for (int j = 0; j < MAX_PLAYERS; ++j) {

		if (_blockSpriteConnectors[j] == nil) continue;

		for (int i = 0; i < [_blockSpriteConnectors[j] count]; ++i) {
			if (((SZEggSpriteConnector*)[_blockSpriteConnectors[j] objectAtIndex:i]).isDead) {
				[_blockSpriteConnectors[j] removeObjectAtIndex:i];
				--i;
			} else {
				[[_blockSpriteConnectors[j] objectAtIndex:i] update];
			}
		}
	}
}

- (void)updateIncomingGarbageDisplayForRunner:(GridRunner*)runner {
	
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
	int spriteX = playerNumber == 0 ? 0 : [[CCDirector sharedDirector] winSize].width - BLOCK_SIZE;
	
	for (int i = 0; i < faceBoulders; ++i) {
		CCSprite* boulder = [CCSprite spriteWithSpriteFrameName:@"incoming2.png"];
		boulder.position = ccp(spriteX + (BLOCK_SIZE / 2), spriteY - ([boulder contentSize].height / 2));
		[_incomingSpriteSheet addChild:boulder];
		
		spriteY -= [boulder contentSize].height + 1;
		
		[_incomingGarbageSprites[playerNumber] addObject:boulder];
	}
	
	for (int i = 0; i < largeBoulders; ++i) {
		CCSprite* boulder = [CCSprite spriteWithSpriteFrameName:@"incoming1.png"];
		boulder.position = ccp(spriteX + (BLOCK_SIZE / 2), spriteY - ([boulder contentSize].height / 2));
		[_incomingSpriteSheet addChild:boulder];
		
		spriteY -= [boulder contentSize].height + 1;
		
		[_incomingGarbageSprites[playerNumber] addObject:boulder];
	}
	
	for (int i = 0; i < garbage; ++i) {
		CCSprite* boulder = [CCSprite spriteWithSpriteFrameName:@"incoming0.png"];
		boulder.position = ccp(spriteX + (BLOCK_SIZE / 2), spriteY - ([boulder contentSize].height / 2));
		[_incomingSpriteSheet addChild:boulder];
		
		spriteY -= [boulder contentSize].height + 1;
		
		[_incomingGarbageSprites[playerNumber] addObject:boulder];
	}
}

- (void)dealloc {
	
	[_eggFactory release];
	
	[self unloadSounds];
	
	for (int i = 0; i < MAX_PLAYERS; ++i) {
		[_runners[i] release];
		[_blockSpriteConnectors[i] release];
		[_incomingGarbageSprites[i] release];
	}
	
	[super dealloc];
}

- (void)createBlockSpriteConnector:(SZEggBase*)block gridX:(int)gridX gridY:(int)gridY connectorArray:(NSMutableArray*)connectorArray {
	
	CCSprite* sprite = nil;
	CCSpriteBatchNode* sheet = nil;
	
	if ([block isKindOfClass:[SZRedEgg class]]) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"red00.png"];
		sheet = _redBlockSpriteSheet;
	} else if ([block isKindOfClass:[SZGreenEgg class]]) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"green00.png"];
		sheet = _greenBlockSpriteSheet;
	} else if ([block isKindOfClass:[SZBlueEgg class]]) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"blue00.png"];
		sheet = _blueBlockSpriteSheet;
	} else if ([block isKindOfClass:[SZYellowEgg class]]) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"yellow00.png"];
		sheet = _yellowBlockSpriteSheet;
	} else if ([block isKindOfClass:[SZOrangeEgg class]]) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"orange00.png"];
		sheet = _orangeBlockSpriteSheet;
	} else if ([block isKindOfClass:[SZPurpleEgg class]]) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"purple00.png"];
		sheet = _purpleBlockSpriteSheet;
	} else if ([block isKindOfClass:[SZGarbageEgg class]]) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"grey00.png"];
		sheet = _garbageBlockSpriteSheet;
	} else if ([block isKindOfClass:[SZGridBottomEgg class]]) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"gridbottom00.png"];
		sheet = _gridBottomBlockSpriteSheet;
	} else if ([block isKindOfClass:[SZGridBottomLeftEgg class]]) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"gridbottomleft00.png"];
		sheet = _gridBottomLeftBlockSpriteSheet;
	} else if ([block isKindOfClass:[SZGridBottomRightEgg class]]) {
		sprite = [CCSprite spriteWithSpriteFrameName:@"gridbottomright00.png"];
		sheet = _gridBottomRightBlockSpriteSheet;
	}
	
	// Connect the sprite and block together
	SZEggSpriteConnector* connector = [[SZEggSpriteConnector alloc] initWithEgg:block sprite:sprite gridX:gridX gridY:gridY];
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
	if (![self moveNextBlockToGridForPlayer:grid.playerNumber block:egg]) {

		// No existing next block exists (this must be a garbage block) so
		// create the connector
		[self addBlockSpriteConnectorForPlayer:grid.playerNumber block:egg];
	}
}

- (void)grid:(SZGrid *)grid didLandGarbageEgg:(SZEggBase *)egg {

	// Offsets all of the blocks in the column so that the column appears to
	// squash under the garbage weight.
	[self hitColumnWithGarbageForPlayerNumber:grid.playerNumber column:egg.x];
}

#pragma mark - SZGridRunnerDelegate

- (void)didGridRunnerAddLiveBlocks:(GridRunner *)gridRunner {

}

- (void)didGridRunnerClearIncomingGarbage:(GridRunner *)gridRunner {
	[self updateIncomingGarbageDisplayForRunner:gridRunner];
}

- (void)didGridRunnerCreateNextBlocks:(GridRunner *)gridRunner {
	[self createNextBlockSpriteConnectorPairForRunner:gridRunner];

	if (gridRunner.playerNumber == 0) {
		[[SZPad instanceTwo] releaseDown];
		_didDrag = NO;
		_columnTarget = -1;
		_dragStartColumn = -1;
		_dragStartX = -1;
	}
}

- (void)didGridRunnerExplodeChain:(GridRunner *)gridRunner sequence:(int)sequence {
	CGFloat pan = [self panForPlayerNumber:gridRunner.playerNumber];
	[[SimpleAudioEngine sharedEngine] playEffect:@"chain.wav" pitch:(1.0 + (sequence * 0.05)) pan:pan gain:1.0];
}

- (void)didGridRunnerExplodeMultipleChains:(GridRunner *)gridRunner {
	NSString* filename = gridRunner.playerNumber == 0 ? @"multichain1.wav" : @"multichain2.wav";
	CGFloat pan = [self panForPlayerNumber:gridRunner.playerNumber];
	[[SimpleAudioEngine sharedEngine] playEffect:filename pitch:1.0 pan:pan gain:1.0];
}

- (void)didGridRunnerMoveLiveBlocks:(GridRunner *)gridRunner {
	CGFloat pan = [self panForPlayerNumber:gridRunner.playerNumber];
	[[SimpleAudioEngine sharedEngine] playEffect:@"move.wav" pitch:1.0 pan:pan gain:1.0];
}

- (void)didGridRunnerRotateLiveBlocks:(GridRunner *)gridRunner {
	CGFloat pan = [self panForPlayerNumber:gridRunner.playerNumber];
	[[SimpleAudioEngine sharedEngine] playEffect:@"rotate.wav" pitch:1.0 pan:pan gain:1.0];
}

- (void)didGridRunnerStartDroppingLiveBlocks:(GridRunner *)gridRunner {

	int players = [Settings sharedSettings].gameType == GamePracticeType ? 1 : 2;

	CGFloat pan = [self panForPlayerNumber:gridRunner.playerNumber];

	// Never play the drop sound for the AI player as it is irritating.
	if (gridRunner.playerNumber == 0 || (gridRunner.playerNumber == 1 && players == 1)) {
		[[SimpleAudioEngine sharedEngine] playEffect:@"drop.wav" pitch:1.0 pan:pan gain:1.0];
	}
}

@end
