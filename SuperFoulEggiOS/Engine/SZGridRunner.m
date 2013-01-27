#import "SZGridRunner.h"
#import "SZEngineConstants.h"
#import "SZNetworkSession.h"
#import "SZEggFactory.h"
#import "SZSettings.h"
#import "SZMessage.h"
#import "SZMessageBus.h"

/**
 * Number of iterations before eggs drop when automatic dropping mode is
 * active.
 */
const int SZAutoDropTime = 2;

/**
 * The bonus given for each successive chain sequenced together.
 */
const int SZChainSequenceGarbageBonus = 6;

/**
 * The maximum speed at which live eggs can be forced to drop, measured in
 * iterations.
 */
const int SZMaximumDropSpeed = 2;

/**
 * The minimum speed at which live eggs can be forced to drop, measured in
 * iterations.
 */
const int SZMinimumDropSpeed = 38;

/**
 * The current drop speed is multiplied by this to produce the number of
 * iterations required until the live eggs are forced to drop.
 */
const int SZDropSpeedMultiplier = 4;

@implementation SZGridRunner

- (id)initWithController:(id <SZGameController>)controller
					grid:(SZGrid *)grid
			playerNumber:(int)playerNumber
				   speed:(int)speed
				isRemote:(BOOL)isRemote {
	
	if ((self = [super init])) {
		_state = SZGridRunnerStateDrop;
		_timer = 0;
		_controller = [controller retain];
		_grid = [grid retain];
		_playerNumber = playerNumber;
		
		_speed = speed;
		_chainMultiplier = 0;
		_incomingGarbageCount = 0;
		_accumulatingGarbageCount = 0;
		
		_droppingLiveEggs = NO;

		for (int i = 0; i < SZLiveEggCount; ++i) {
			_nextEggs[i] = [[SZEggFactory sharedFactory] newEggForPlayerNumber:_playerNumber];
		}

		_isRemote = isRemote;

		if (_isRemote) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRemoteMoveDown) name:SZRemoteMoveDownNotification object:nil];
		}
	}
	
	return self;
}

- (void)receiveRemoteMoveDown {
	if ([_grid hasLiveEggs]) [_grid dropLiveEggs];
}

- (void)dealloc {
	for (int i = 0; i < SZLiveEggCount; ++i) {
		[_nextEggs[i] release];
	}

	if (_isRemote) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:SZRemoteMoveDownNotification object:nil];
	}
	
	[_grid release];
	[_controller release];
	
	[super dealloc];
}

- (SZEggBase *)nextEgg:(int)index {
	NSAssert(index < 2, @"Index must be less than 2.");
	
	return _nextEggs[index];
}

- (void)dropGarbage {
	
	// Garbage eggs are dropping down the screen
	
	_timer = 0;
	
	if (![_grid dropEggs]) {
		
		// Eggs have stopped dropping, so we need to run the landing
		// animations
		_state = SZGridRunnerStateLanding;
	}
}

- (void)drop {
	
	// Eggs are dropping down the screen automatically
	
	if (_timer < SZAutoDropTime) return;
	
	_timer = 0;
	
	if (![_grid dropEggs]) {
		
		// Eggs have stopped dropping, so we need to run the landing
		// animations
		_state = SZGridRunnerStateLanding;
	}
}

- (void)land {
	
	// All animations have finished, so establish connections between eggs now
	// that they have landed
	[_grid connectEggs];
	
	// Attempt to explode any chains that exist in the grid
	int eggs = [_grid explodeEggs];
	
	if (eggs > 0) {
		
		[_delegate didGridRunnerExplodeChain:self sequence:_chainMultiplier];
		
		++_chainMultiplier;
		
		// Outgoing garbage is only relevant to two-player games, but we can
		// run it in all games with no negative effects.
		int garbage = 0;
		
		if (_chainMultiplier == 1) {
			
			// One egg for the chain and one egg for each egg on top of the
			// required minimum number
			garbage = eggs - (SZChainLength - 1);
		} else {
			
			// If we're in a sequence of chains, we add 6 eggs each sequence
			garbage = SZChainSequenceGarbageBonus;
			
			// Add any additional eggs on top of the standard chain length
			garbage += eggs - SZChainLength;
		}
		
		_accumulatingGarbageCount += garbage;
		
		// We need to run the explosion animations next
		_state = SZGridRunnerStateExploding;
		
	} else if (_incomingGarbageCount > 0) {
		
		// Add any incoming garbage eggs
		[_grid addGarbage:_incomingGarbageCount randomPlacement:[SZSettings sharedSettings].gameType != SZGameTypeTwoPlayer];
		
		// Switch back to the drop state
		_state = SZGridRunnerStateDropGarbage;
		
		_incomingGarbageCount = 0;
		
		[_delegate didGridRunnerClearIncomingGarbage:self];
	} else if (_state != SZGridRunnerStateWaitingForNewEgg) {
		_state = SZGridRunnerStateWaitingForNewEgg;

		if ([SZSettings sharedSettings].gameType == SZGameTypeTwoPlayer) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nextEggReady:) name:SZRemoteReadyForNextEggNotification object:nil];
			
			[[SZNetworkSession sharedSession] sendReadyForNextEgg:_playerNumber];
		}
	}
}

- (void)processIncomingGarbageMessages {

	BOOL receivedGarbage = NO;

	SZMessage *message = [[SZMessageBus sharedMessageBus] nextMessageForPlayerNumber:_playerNumber];

	while (message && message.type == SZMessageTypeGarbage) {
		receivedGarbage = YES;

		_incomingGarbageCount += [message.info[@"Count"] intValue];

		[[SZMessageBus sharedMessageBus] removeNextMessageForPlayerNumber:_playerNumber];

		message = [[SZMessageBus sharedMessageBus] nextMessageForPlayerNumber:_playerNumber];
	}

	if (receivedGarbage) {
		[_delegate didGridRunnerReceiveGarbage:self];
	}
}

- (void)live {
	
	// Player-controllable eggs are in the grid
	[self processIncomingGarbageMessages];

	if ([_grid hasLiveEggs]) {
		
		// Work out how many frames we need to wait until the eggs drop
		// automatically
		int timeToDrop = SZMinimumDropSpeed - (SZDropSpeedMultiplier * _speed);
		
		if (timeToDrop < SZMaximumDropSpeed) timeToDrop = SZMaximumDropSpeed;
		
		// Process user input
		if ([_controller isLeftHeld]) {
			if ([_grid moveLiveEggsLeft]) {
				[_delegate didGridRunnerMoveLiveEggs:self];

				[[SZMessageBus sharedMessageBus] sendBlockMove:SZBlockMoveTypeLeft fromPlayerNumber:_playerNumber];
            }
		} else if ([_controller isRightHeld]) {
			if ([_grid moveLiveEggsRight]) {
				[_delegate didGridRunnerMoveLiveEggs:self];
				
				[[SZMessageBus sharedMessageBus] sendBlockMove:SZBlockMoveTypeRight fromPlayerNumber:_playerNumber];
			}
		}
		
		if ([_controller isDownHeld] && (_timer % 2 == 0)) {
			
			// Force eggs to drop
			_timer = timeToDrop;
			
			if (!_droppingLiveEggs) {
				_droppingLiveEggs = YES;
				
				[_delegate didGridRunnerStartDroppingLiveEggs:self];

				[[SZMessageBus sharedMessageBus] sendBlockMove:SZBlockMoveTypeDown fromPlayerNumber:_playerNumber];
			}
		} else if (![_controller isDownHeld]) {
			_droppingLiveEggs = NO;
		}
		
		if ([_controller isRotateClockwiseHeld]) {
			if ([_grid rotateLiveEggsClockwise]) {
				[_delegate didGridRunnerRotateLiveEggs:self];

				[[SZMessageBus sharedMessageBus] sendBlockMove:SZBlockMoveTypeRotateClockwise fromPlayerNumber:_playerNumber];
			}
		} else if ([_controller isRotateAntiClockwiseHeld]) {
			if ([_grid rotateLiveEggsAntiClockwise]) {
				[_delegate didGridRunnerRotateLiveEggs:self];

				[[SZMessageBus sharedMessageBus] sendBlockMove:SZBlockMoveTypeRotateAnticlockwise fromPlayerNumber:_playerNumber];
			}
		}
		
		// Drop live eggs if the timer has expired
		if (_timer >= timeToDrop) {
			_timer = 0;
			
			[_grid dropLiveEggs];
			[[SZMessageBus sharedMessageBus] sendBlockMove:SZBlockMoveTypeDown fromPlayerNumber:_playerNumber];
		}
	} else {
		
		// At least one of the eggs in the live pair has touched down.
		// We need to drop the other egg automatically
		_droppingLiveEggs = NO;
		_state = SZGridRunnerStateDrop;
	}
}

- (void)waitForNewEgg {
	if ([SZSettings sharedSettings].gameType == SZGameTypeTwoPlayer) {
		[self land];
	} else {
		[self nextEggReady:nil];
	}
}

- (void)nextEggReady:(NSNotification *)notification {

	if (notification) {
		int playerNumber = [notification.userInfo[@"PlayerNumber"] intValue];

		if (playerNumber != _playerNumber) {

			NSLog(@"Ignoring next egg for player %d", playerNumber);

			return;
		}
	}

	[[NSNotificationCenter defaultCenter] removeObserver:self name:SZRemoteReadyForNextEggNotification object:nil];

	NSLog(@"Got next egg for player %d", [notification.userInfo[@"PlayerNumber"] intValue]);

	BOOL addedEggs = [_grid addLiveEggs:_nextEggs[0] egg2:_nextEggs[1]];

	if (!addedEggs) {

		// Cannot add more eggs - game is over
		_state = SZGridRunnerStateDead;
	} else {

		if (_chainMultiplier > 1) {
			[_delegate didGridRunnerExplodeMultipleChains:self];
		}

		_chainMultiplier = 0;

		// Queue up outgoing eggs for the other player

		if (_accumulatingGarbageCount > 0) {
			[[SZMessageBus sharedMessageBus] sendGarbage:_accumulatingGarbageCount fromPlayerNumber:_playerNumber toPlayerNumber:1 - _playerNumber];
		}

		_accumulatingGarbageCount = 0;

		[_nextEggs[0] release];
		[_nextEggs[1] release];

		_nextEggs[0] = nil;
		_nextEggs[1] = nil;

		// Fetch the next eggs from the egg factory and remember them
		for (int i = 0; i < SZLiveEggCount; ++i) {
			_nextEggs[i] = [[SZEggFactory sharedFactory] newEggForPlayerNumber:_playerNumber];
		}

		[_delegate didGridRunnerCreateNextEggs:self];
		[_delegate didGridRunnerAddLiveEggs:self];

		_state = SZGridRunnerStateLive;
	}
}

- (void)iterate {
	
	// Returns true if any eggs have any logic still in progress
	BOOL iterated = [_grid iterate];
	
	++_timer;
	
	switch (_state) {
		case SZGridRunnerStateWaitingForNewEgg:
			[self waitForNewEgg];
			break;

		case SZGridRunnerStateDropGarbage:
			[self dropGarbage];
			break;
			
		case SZGridRunnerStateDrop:
			[self drop];
			break;
			
		case SZGridRunnerStateLanding:
			
			// Wait until eggs stop iterating
			if (!iterated) {
				[self land];
			}
			
			break;
			
		case SZGridRunnerStateExploding:
			
			// Wait until eggs stop iterating
			if (!iterated) {
				
				// All iterations have finished - we need to drop any eggs that
				
				// are now sat on holes in the grid
				_state = SZGridRunnerStateDrop;
			}
			
			break;
			
		case SZGridRunnerStateLive:
			[self live];
			break;
			
		case SZGridRunnerStateDead:
			break;
	}
}

- (BOOL)isDead {
	return _state == SZGridRunnerStateDead;
}

@end
