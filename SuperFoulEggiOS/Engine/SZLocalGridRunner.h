#import <Foundation/NSObject.h>

#import "SZGrid.h"
#import "SZGameController.h"
#import "SZEggBase.h"
#import "SZEngineConstants.h"
#import "SZGridRunner.h"

/**
 * Controls a grid.  Maintains a state machine that tracks what should happen
 * currently and next as the game progresses.
 */
@interface SZLocalGridRunner : NSObject <SZGridRunner> {
	SZGridRunnerState _state;					/**< The state of the state machine. */
	int _timer;									/**< Frames since the last event took place. */
	SZEggBase *_nextEggs[SZLiveEggCount];		/**< Array of 2 eggs that will be placed next. */
	
	int _speed;									/**< Current speed. */
	int _chainMultiplier;						/**< Increases when multiple chains are exploded in one												 move. */
	
	int _accumulatingGarbageCount;				/**< Outgoing garbage eggs that accumulate during chain
													 sequences. */
	
	BOOL _droppingLiveEggs;						/**< True if live eggs are dropping automatically. */
}

@property (readwrite, assign) id <SZGridRunnerDelegate> delegate;

/**
 * Number of garbage eggs sent from the other player.
 */
@property (readonly) int incomingGarbageCount;

/**
 * The zero-based number of the current player.
 */
@property (readonly) int playerNumber;

/**
 * The grid controlled by this grid runner.
 */
@property (readonly, retain) SZGrid *grid;

/**
 * The controller used for input.
 */
@property (readonly, retain) id <SZGameController> controller;

/**
 * Initialise a new instance of the class.
 * @param controller A controller object that will provide input for the
 * movement of live eggs.
 * @param grid Grid to run.
 * @param playerNumber The unique number of the player using this runner.
 * @param speed The auto drop speed.
 */
- (id)initWithController:(id <SZGameController>)controller
					grid:(SZGrid *)grid
			playerNumber:(int)playerNumber
				   speed:(int)speed;

@end
