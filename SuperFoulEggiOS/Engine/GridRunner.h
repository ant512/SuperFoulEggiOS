#import <Foundation/NSObject.h>

#import "SZGrid.h"
#import "SZGameController.h"
#import "SZEggBase.h"
#import "SZEggFactory.h"

@class GridRunner;

@protocol SZGridRunnerDelegate <NSObject>

- (void)didGridRunnerMoveLiveBlocks:(GridRunner *)gridRunner;
- (void)didGridRunnerRotateLiveBlocks:(GridRunner *)gridRunner;
- (void)didGridRunnerStartDroppingLiveBlocks:(GridRunner *)gridRunner;
- (void)didGridRunnerAddLiveBlocks:(GridRunner *)gridRunner;
- (void)didGridRunnerCreateNextBlocks:(GridRunner *)gridRunner;
- (void)didGridRunnerExplodeMultipleChains:(GridRunner *)gridRunner;
- (void)didGridRunnerClearIncomingGarbage:(GridRunner *)gridRunner;
- (void)didGridRunnerExplodeChain:(GridRunner *)gridRunner sequence:(int)sequence;

@end

/**
 * All possible states of the state machine.
 */
typedef NS_ENUM(NSUInteger, SZGridRunnerState) {
	SZGridRunnerStateDrop = 0,					/**< Blocks are dropping automatically. */
	SZGridRunnerStateDropGarbage = 1,			/**< Garbage blocks are dropping. */
	SZGridRunnerStateLive = 2,					/**< Live, user-controlled blocks are in play. */
	SZGridRunnerStateLanding = 3,				/**< Blocks are running their landing animations. */
	SZGridRunnerStateExploding = 4,				/**< Blocks are running their exploding animations. */
	SZGridRunnerStateDead = 5					/**< Game is over. */
};

/**
 * Controls a grid.  Maintains a state machine that tracks what should happen
 * currently and next as the game progresses.
 */
@interface GridRunner : NSObject {
	SZGridRunnerState _state;					/**< The state of the state machine. */
	int _timer;									/**< Frames since the last event took place. */
	SZEggFactory* _blockFactory;				/**< Produces next blocks for the grid. */
	SZEggBase* _nextBlocks[LIVE_BLOCK_COUNT];	/**< Array of 2 blocks that will be placed next. */

	int _speed;									/**< Current speed. */
	int _chainMultiplier;						/**< Increases when multiple chains are exploded in one move. */

	int _accumulatingGarbageCount;				/**< Outgoing garbage blocks that accumulate during chain
													 sequences.  At the end of a sequence they are moved to the
													 _outgoinggGarbageCount member. */

	BOOL _droppingLiveEggs;					/**< True if live blocks are dropping automatically. */
}

@property (readwrite, assign) id <SZGridRunnerDelegate> delegate;

/**
 * Number of garbage blocks to send to the other player.
 */
@property (readonly) int outgoingGarbageCount;

/**
 * Number of garbage blocks sent from the other player.
 */
@property (readonly) int incomingGarbageCount;

/**
 * The zero-based number of the current player.
 */
@property (readonly) int playerNumber;

/**
 * The grid controlled by this grid runner.
 */
@property (readonly, retain) SZGrid* grid;

/**
 * The controller used for input.
 */
@property (readonly, retain) id <SZGameController> controller;

/**
 * Initialise a new instance of the class.
 * @param controller A controller object that will provide input for the
 * movement of live blocks.
 * @param grid Grid to run.
 * @param blockFactory The block factory to use to produce next blocks for the
 * grid.
 * @param playerNumber The unique number of the player using this runner.
 * @param speed The auto drop speed.
 */
- (id)initWithController:(id <SZGameController>)controller
					grid:(SZGrid*)grid
					blockFactory:(SZEggFactory*)blockFactory
					playerNumber:(int)playerNumber
					speed:(int)speed;

/**
 * Deallocates the object.
 */
- (void)dealloc;

/**
 * Process a single iteration of the state machine/grid logic.  This model
 * enables other code to be run between iterations of the grid (for example,
 * if two grids are running because we've got a two-player game).
 */
- (void)iterate;

/**
 * Get the specified next block.  Valid indices are 0 and 1.
 * @param index The index of the block to retrieve.
 * @return The requested next block.
 */
- (SZEggBase*)nextBlock:(int)index;

/**
 * Increase the amount of incoming garbage blocks by the specified amount.
 * Garbage can only be added when the grid runner is in its "live" state.
 * @param count The number of incoming garbage blocks to increase by.
 * @return True if the garbage was added; false if not.
 */
- (BOOL)addIncomingGarbage:(int)count;

/**
 * Resets the number of outgoing garbage blocks to 0.
 */
- (void)clearOutgoingGarbageCount;

/**
 * Check if the game is over for this grid runner.
 * @return True if the game is over.
 */
- (BOOL)isDead;

/**
 * Drops blocks in the grid.  Called when the grid is in drop mode.
 */
- (void)drop;

/**
 * Lands blocks in the grid.  Called when the grid is in land mode.
 */
- (void)land;

/**
 * Process live blocks in the grid.  Called when the grid is in live mode.
 */
- (void)live;

/**
 * Check if the grid can receive garbage.  Grid can only receive garbage
 * whilst in the live state.  If garbage is received at other times it is
 * possible that the player will forever be stuck watching garbage dropping
 * down the screen.
 * @return True if the grid can receive garbage.
 */
- (BOOL)canReceiveGarbage;

@end
