#import "SZRemoteGridRunner.h"
#import "SZEngineConstants.h"
#import "SZEggFactory.h"
#import "SZSettings.h"
#import "SZMessage.h"
#import "SZMessageBus.h"

@implementation SZRemoteGridRunner

- (id)initWithGrid:(SZGrid *)grid
	  playerNumber:(int)playerNumber
			 speed:(int)speed {
	
	if ((self = [super init])) {
		[self setState:SZGridRunnerStateDrop];
		_timer = 0;
		_grid = [grid retain];
		_playerNumber = playerNumber;
		
		_speed = speed;
		_chainMultiplier = 0;
		_incomingGarbageCount = 0;
		
		for (int i = 0; i < SZLiveEggCount; ++i) {
			_nextEggs[i] = [[SZEggFactory sharedFactory] newEggForPlayerNumber:_playerNumber];
		}
	}
	
	return self;
}

- (void)dealloc {
	for (int i = 0; i < SZLiveEggCount; ++i) {
		[_nextEggs[i] release];
	}

	[_grid release];
	
	[super dealloc];
}

- (SZEggBase *)nextEgg:(int)index {
	NSAssert(index < 2, @"Index must be less than 2.");
	
	return _nextEggs[index];
}

- (void)dropGarbage {
	NSAssert(_state == SZGridRunnerStateDropGarbage, @"Illegal state");
	
	// Garbage eggs are dropping down the screen
	
	_timer = 0;
	
	if (![_grid dropEggs]) {
		
		// Eggs have stopped dropping, so we need to run the landing
		// animations
		[self setState:SZGridRunnerStateLanding];
	}
}

- (void)drop {
	
	NSAssert(_state == SZGridRunnerStateDrop, @"Illegal state");
	
	// Eggs are dropping down the screen automatically
	
	if (_timer < SZAutoDropTime) return;
	
	_timer = 0;
	
	if (![_grid dropEggs]) {
		
		// Eggs have stopped dropping, so we need to run the landing
		// animations
		[self setState:SZGridRunnerStateLanding];
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
		
		// We need to run the explosion animations next
		[self setState:SZGridRunnerStateExploding];
		
	} else if (_incomingGarbageCount > 0) {
		
		// Add any incoming garbage eggs
		[_grid addGarbage:_incomingGarbageCount randomPlacement:[SZSettings sharedSettings].gameType != SZGameTypeTwoPlayer];
		
		// Switch back to the drop state
		[self setState:SZGridRunnerStateDropGarbage];
		
		_incomingGarbageCount = 0;
		
		[_delegate didGridRunnerClearIncomingGarbage:self];
	} else if (_state != SZGridRunnerStateWaitingForNewEgg) {
		[self setState:SZGridRunnerStateWaitingForNewEgg];
	}
}

- (void)processIncomingGarbageMessages {

	int count = 0;
	
	SZMessage *message = [[SZMessageBus sharedMessageBus] nextMessageForPlayerNumber:_playerNumber];
	
	while (message && message.type == SZMessageTypeGarbage) {
		
		count += [message.info[@"Count"] intValue];
		
		[[SZMessageBus sharedMessageBus] removeNextMessageForPlayerNumber:_playerNumber];
		
		message = [[SZMessageBus sharedMessageBus] nextMessageForPlayerNumber:_playerNumber];
	}

	_bufferedGarbageCount += count;

	[[SZMessageBus sharedMessageBus] sendGarbage:count fromPlayerNumber:_playerNumber toPlayerNumber:_playerNumber];
}

- (void)live {
	
	NSAssert(_state == SZGridRunnerStateLive, @"Illegal state");

	if (_bufferedGarbageCount > 0) {
		_incomingGarbageCount += _bufferedGarbageCount;
		_bufferedGarbageCount = 0;

		[_delegate didGridRunnerReceiveGarbage:self];
	}
	
	if ([_grid hasLiveEggs]) {
		
		// Process user input
		SZMessage *message = [[SZMessageBus sharedMessageBus] nextMessageForPlayerNumber:_playerNumber];
		
		if (message.type == SZMessageTypeMove) {
			
			//NSLog(@"Move %@", message.info[@"Move"]);
			
			SZBlockMoveType moveType = [message.info[@"Move"] intValue];
			
			switch (moveType) {
				case SZBlockMoveTypeLeft:
					if ([_grid moveLiveEggsLeft]) {
						[_delegate didGridRunnerMoveLiveEggs:self];
					}
					break;
				
				case SZBlockMoveTypeRight:
					if ([_grid moveLiveEggsRight]) {
						[_delegate didGridRunnerMoveLiveEggs:self];
					}
					break;

				case SZBlockMoveTypeDown:
					[_delegate didGridRunnerStartDroppingLiveEggs:self];
					[_grid dropLiveEggs];

					break;
					
				case SZBlockMoveTypeRotateClockwise:
					if ([_grid rotateLiveEggsClockwise]) {
						[_delegate didGridRunnerRotateLiveEggs:self];
					}
					break;
					
				case SZBlockMoveTypeRotateAnticlockwise:
					if ([_grid rotateLiveEggsAntiClockwise]) {
						[_delegate didGridRunnerRotateLiveEggs:self];
					}
					break;
			}

			[[SZMessageBus sharedMessageBus] removeNextMessageForPlayerNumber:_playerNumber];
		}
	} else {
		
		// At least one of the eggs in the live pair has touched down.
		// We need to drop the other egg automatically
		[self setState:SZGridRunnerStateDrop];
	}
}

- (void)waitForNewEgg {
	SZMessage *message = [[SZMessageBus sharedMessageBus] nextMessageForPlayerNumber:_playerNumber];

	while (message && message.type != SZMessageTypePlaceNextEggs) {
		[[SZMessageBus sharedMessageBus] removeNextMessageForPlayerNumber:_playerNumber];
		message = [[SZMessageBus sharedMessageBus] nextMessageForPlayerNumber:_playerNumber];
	}
	
	if (message.type == SZMessageTypePlaceNextEggs) {
		[self addNextEgg];
		
		[[SZMessageBus sharedMessageBus] removeNextMessageForPlayerNumber:_playerNumber];
	} else {
		[self land];
	}
}

- (void)addNextEgg {
	
	BOOL addedEggs = [_grid addLiveEggs:_nextEggs[0] egg2:_nextEggs[1]];
	
	if (!addedEggs) {
		
		// Cannot add more eggs - game is over
		[self setState:SZGridRunnerStateDead];
	} else {
		
		if (_chainMultiplier > 1) {
			[_delegate didGridRunnerExplodeMultipleChains:self];
		}
		
		_chainMultiplier = 0;
		
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
		
		[self setState:SZGridRunnerStateLive];
	}
}

- (void)iterate {

	SZMessage *message = [[SZMessageBus sharedMessageBus] nextMessageForPlayerNumber:_playerNumber];
	//if (message) NSLog(@"%@", message);

	if (_state == SZGridRunnerStateWaitingForNewEgg && message.type != SZMessageTypePlaceNextEggs) {
		NSLog(@"Waiting for egg; got %d", message.type);
	}

	[self processIncomingGarbageMessages];

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
				[self setState:SZGridRunnerStateDrop];
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

- (void)setState:(SZGridRunnerState)state {
	_state = state;
	
	NSLog(@"New state: %d", state);
}

@end
