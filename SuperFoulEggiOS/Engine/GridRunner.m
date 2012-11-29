#import "GridRunner.h"

/**
 * Number of iterations before blocks drop when automatic dropping mode is
 * active.
 */
const int SZAutoDropTime = 2;

/**
 * The bonus given for each successive chain sequenced together.
 */
const int SZChainSequenceGarbageBonus = 6;

/**
 * The maximum speed at which live blocks can be forced to drop, measured in
 * iterations.
 */
const int SZMaximumDropSpeed = 2;

/**
 * The minimum speed at which live blocks can be forced to drop, measured in
 * iterations.
 */
const int SZMinimumDropSpeed = 38;

/**
 * The current drop speed is multiplied by this to produce the number of
 * iterations required until the live blocks are forced to drop.
 */
const int SZDropSpeedMultiplier = 4;

@implementation GridRunner

- (id)initWithController:(id <SZGameController>)controller
					grid:(SZGrid*)grid
					eggFactory:(SZEggFactory*)eggFactory
					playerNumber:(int)playerNumber
					speed:(int)speed {

	if ((self = [super init])) {
		_state = SZGridRunnerStateDrop;
		_timer = 0;
		_controller = [controller retain];
		_grid = [grid retain];
		_eggFactory = eggFactory;
		_playerNumber = playerNumber;

		_speed = speed;
		_chainMultiplier = 0;
		_outgoingGarbageCount = 0;
		_incomingGarbageCount = 0;
		_accumulatingGarbageCount = 0;

		_droppingLiveEggs = NO;

		// Ensure we have some initial blocks to add to the grid
		for (int i = 0; i < LIVE_BLOCK_COUNT; ++i) {
			_nextBlocks[i] = [_eggFactory newEggForPlayerNumber:_playerNumber];
		}
	}
	
	return self;
}

- (void)dealloc {
	for (int i = 0; i < LIVE_BLOCK_COUNT; ++i) {
		[_nextBlocks[i] release];
	}

	[_grid release];
	[_controller release];
	
	[super dealloc];
}

- (SZEggBase*)nextBlock:(int)index {
	NSAssert(index < 2, @"Index must be less than 2.");
	
	return _nextBlocks[index];
}

- (void)dropGarbage {
	
	// Garbage blocks are dropping down the screen
	
	_timer = 0;
	
	if (![_grid dropEggs]) {
		
		// Blocks have stopped dropping, so we need to run the landing
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

			// One block for the chain and one block for each block on
			// top of the required minimum number
			garbage = eggs - (CHAIN_LENGTH - 1);
		} else {

			// If we're in a sequence of chains, we add 6 blocks each
			// sequence
			garbage = SZChainSequenceGarbageBonus;

			// Add any additional blocks on top of the standard
			// chain length
			garbage += eggs - CHAIN_LENGTH;
		}

		_accumulatingGarbageCount += garbage;
		
		// We need to run the explosion animations next
		_state = SZGridRunnerStateExploding;

	} else if (_incomingGarbageCount > 0) {

		// Add any incoming garbage blocks
		[_grid addGarbage:_incomingGarbageCount];

		// Switch back to the drop state
		_state = SZGridRunnerStateDropGarbage;

		_incomingGarbageCount = 0;

		[_delegate didGridRunnerClearIncomingGarbage:self];
	} else {

		// Nothing exploded, so we can put a new live block into
		// the grid
		BOOL addedEggs = [_grid addLiveEggs:_nextBlocks[0] egg2:_nextBlocks[1]];

		if (!addedEggs) {

			// Cannot add more blocks - game is over
			_state = SZGridRunnerStateDead;
		} else {
			
			[_nextBlocks[0] release];
			[_nextBlocks[1] release];
			
			_nextBlocks[0] = nil;
			_nextBlocks[1] = nil;

			// Fetch the next blocks from the block factory and remember
			// them
			for (int i = 0; i < LIVE_BLOCK_COUNT; ++i) {
				_nextBlocks[i] = [_eggFactory newEggForPlayerNumber:_playerNumber];
			}

			[_delegate didGridRunnerCreateNextBlocks:self];

			if (_chainMultiplier > 1) {
				[_delegate didGridRunnerExplodeMultipleChains:self];
			}

			_chainMultiplier = 0;

			// Queue up outgoing blocks for the other player
			_outgoingGarbageCount += _accumulatingGarbageCount;
			_accumulatingGarbageCount = 0;

			[_delegate didGridRunnerAddLiveBlocks:self];

			_state = SZGridRunnerStateLive;
		}
	}
}

- (void)live {

	// Player-controllable eggs are in the grid

	if ([_grid hasLiveEggs]) {

		// Work out how many frames we need to wait until the blocks drop
		// automatically
		int timeToDrop = SZMinimumDropSpeed - (SZDropSpeedMultiplier * _speed);

		if (timeToDrop < SZMaximumDropSpeed) timeToDrop = SZMaximumDropSpeed;

		// Process user input
		if ([_controller isLeftHeld]) {
			if ([_grid moveLiveEggsLeft]) {
				[_delegate didGridRunnerMoveLiveBlocks:self];
            }
		} else if ([_controller isRightHeld]) {
			if ([_grid moveLiveEggsRight]) {
				[_delegate didGridRunnerMoveLiveBlocks:self];
			}
		}

		if ([_controller isDownHeld] && (_timer % 2 == 0)) {

			// Force blocks to drop
			_timer = timeToDrop;

			if (!_droppingLiveEggs) {
				_droppingLiveEggs = YES;

				[_delegate didGridRunnerStartDroppingLiveBlocks:self];
			}
		} else if (![_controller isDownHeld]) {
			_droppingLiveEggs = NO;
		}
		
		if ([_controller isRotateClockwiseHeld]) {
			if ([_grid rotateLiveEggsClockwise]) {
				[_delegate didGridRunnerRotateLiveBlocks:self];
			}
		} else if ([_controller isRotateAntiClockwiseHeld]) {
			if ([_grid rotateLiveEggsAntiClockwise]) {
				[_delegate didGridRunnerRotateLiveBlocks:self];
			}
		}

		// Drop live blocks if the timer has expired
		if (_timer >= timeToDrop) {
			_timer = 0;
			[_grid dropLiveEggs];
		}
	} else {

		// At least one of the blocks in the live pair has touched down.
		// We need to drop the other block automatically
		_droppingLiveEggs = NO;
		_state = SZGridRunnerStateDrop;
	}
}

- (void)iterate {

	// Returns true if any blocks have any logic still in progress
	BOOL iterated = [_grid iterate];

	++_timer;

	switch (_state) {
		case SZGridRunnerStateDropGarbage:
			[self dropGarbage];
			break;
			
		case SZGridRunnerStateDrop:
			[self drop];
			break;
		
		case SZGridRunnerStateLanding:
			
			// Wait until blocks stop iterating
			if (!iterated) {
				[self land];
			}

			break;

		case SZGridRunnerStateExploding:

			// Wait until blocks stop iterating
			if (!iterated) {

				// All iterations have finished - we need to drop any blocks
				// that are now sat on holes in the grid
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

- (BOOL)addIncomingGarbage:(int)count {
	if (![self canReceiveGarbage]) return NO;
	if (count < 1) return NO;

	_incomingGarbageCount += count;

	return YES;
}

- (void)clearOutgoingGarbageCount {
	_outgoingGarbageCount = 0;
}

- (BOOL)canReceiveGarbage {
	return _state == SZGridRunnerStateLive;
}

- (BOOL)isDead {
	return _state == SZGridRunnerStateDead;
}

@end
