#import <Foundation/Foundation.h>

@class SZGrid;
@class SZEggBase;

@protocol SZGridRunner;

/**
 * All possible states of the state machine.
 */
typedef NS_ENUM(NSUInteger, SZGridRunnerState) {
	SZGridRunnerStateDrop = 0,					/**< Eggs are dropping automatically. */
	SZGridRunnerStateDropGarbage = 1,			/**< Garbage eggs are dropping. */
	SZGridRunnerStateLive = 2,					/**< Live, user-controlled eggs are in play. */
	SZGridRunnerStateLanding = 3,				/**< Eggs are running their landing animations. */
	SZGridRunnerStateExploding = 4,				/**< Eggs are running their exploding animations. */
	SZGridRunnerStateDead = 5,					/**< Game is over. */
	SZGridRunnerStateWaitingForNewEgg = 6		/**< Waiting for an egg to be created in the egg factory. */
};

@protocol SZGridRunnerDelegate <NSObject>

- (void)didGridRunnerMoveLiveEggs:(id <SZGridRunner>)gridRunner;
- (void)didGridRunnerRotateLiveEggs:(id <SZGridRunner>)gridRunner;
- (void)didGridRunnerStartDroppingLiveEggs:(id <SZGridRunner>)gridRunner;
- (void)didGridRunnerAddLiveEggs:(id <SZGridRunner>)gridRunner;
- (void)didGridRunnerCreateNextEggs:(id <SZGridRunner>)gridRunner;
- (void)didGridRunnerExplodeMultipleChains:(id <SZGridRunner>)gridRunner;
- (void)didGridRunnerClearIncomingGarbage:(id <SZGridRunner>)gridRunner;
- (void)didGridRunnerExplodeChain:(id <SZGridRunner>)gridRunner sequence:(int)sequence;
- (void)didGridRunnerReceiveGarbage:(id <SZGridRunner>)gridRunner;

@end

@protocol SZGridRunner <NSObject>

/**
 * The zero-based number of the current player.
 */
@property (readonly) int playerNumber;

@property (readwrite, assign) id <SZGridRunnerDelegate> delegate;

/**
 * The grid controlled by this grid runner.
 */
@property (readonly, retain) SZGrid *grid;

/**
 * Number of garbage eggs sent from the other player.
 */
@property (readonly) int incomingGarbageCount;

/**
 * Process a single iteration of the state machine/grid logic.  This model
 * enables other code to be run between iterations of the grid (for example,
 * if two grids are running because we've got a two-player game).
 */
- (void)iterate;

/**
 * Get the specified next egg.  Valid indices are 0 and 1.
 * @param index The index of the egg to retrieve.
 * @return The requested next egg.
 */
- (SZEggBase *)nextEgg:(int)index;

/**
 * Check if the game is over for this grid runner.
 * @return True if the game is over.
 */
- (BOOL)isDead;

@end
