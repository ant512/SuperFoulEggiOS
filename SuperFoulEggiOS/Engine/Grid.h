#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>

#import "SZEggBase.h"
#import "GridBase.h"

#define CHAIN_LENGTH 4
#define LIVE_BLOCK_COUNT 2

@class Grid;
@class SZEggBase;

@protocol SZGridDelegate <NSObject>
@required

- (void)didLandEggInGrid:(Grid *)grid;
- (void)didLandGarbageEggInGrid:(Grid *)grid;
- (void)didAddGarbageEggRowToGrid:(Grid *)grid;

- (void)grid:(Grid *)grid didLandGarbageEgg:(SZEggBase *)egg;
- (void)grid:(Grid *)grid didAddEgg:(SZEggBase *)egg;

@optional

- (void)grid:(Grid *)grid didRemoveEgg:(SZEggBase *)egg;

@end

/**
 * Extends the GridBase class with events that fire whenever anything
 * interesting happens, and a set of game-specific functions for manipulating
 * the blocks.
 */
@interface Grid : GridBase {
@private
	SZEggBase* _liveBlocks[LIVE_BLOCK_COUNT];	/**< The co-ordinates of the two live blocks in the grid. */
	BOOL _hasLiveBlocks;						/**< True if the grid has player-controlled blocks; false if not. */
	int _playerNumber;							/**< The zero-based number of the player controlling this grid. */
}

@property (readwrite, assign) id <SZGridDelegate> delegate;

/**
 * Check if the grid has live blocks.
 */
@property (readonly) BOOL hasLiveBlocks;

/**
 * The 0-based number of the player controlling the grid.
 */
@property (readonly) int playerNumber;

/**
 * Initialises a new instance of the class.
 * @param playerNumber The 0-based number of the player controlling the grid.
 */
- (id)initWithPlayerNumber:(int)playerNumber;

/**
 * Add a block to the grid.  The grid assumes ownership of the block.
 * @param x The x co-ordinate of the block.
 * @param y The y co-ordinate of the block.
 */
- (void)addBlock:(SZEggBase*)block x:(int)x y:(int)y;

/**
 * Removes and deallocates the block at the specified co-ordinates.
 * @param x The x co-ordinate of the block to remove.
 * @param y The y co-ordinate of the block to remove.
 */
- (void)removeBlockAtX:(int)x y:(int)y;

/**
 * Explodes all eligible chains of blocks in the grid.
 * @return The number of blocks exploded.
 */
- (int)explodeBlocks;

/**
 * Drops the live blocks down half of one grid square.
 */
- (void)dropLiveBlocks;

/**
 * Drops all blocks down half of one grid square.
 * @return True if any blocks drop; false if not.
 */
- (BOOL)dropBlocks;

/**
 * Attempts to move the live blocks one grid square to the left.
 * @return True if the move was successful; false if not.
 */
- (BOOL)moveLiveBlocksLeft;

/**
 * Attempts to move the live blocks one grid square to the right.
 * @return True if the move was successful; false if not.
 */
- (BOOL)moveLiveBlocksRight;

/**
 * Attempts to rotate the live blocks clockwise.
 * @return True if the rotation was successful; false if not.
 */
- (BOOL)rotateLiveBlocksClockwise;

/**
 * Attempts to rotate the live blocks anti-clockwise.
 * @return True if the rotation was successful; false if not.
 */
- (BOOL)rotateLiveBlocksAntiClockwise;

/**
 * Attempts to add the specified blocks to the grid as new live blocks.  The
 * grid assumes ownership of the blocks.
 * @param block1 The left-hand block in the new live pair.
 * @param block2 The right-hand block in the new live pair.
 * @return True if the blocks were added; false if they could not be added.
 * Failure indicates game over.
 */
- (BOOL)addLiveBlocks:(SZEggBase*)block1 block2:(SZEggBase*)block2;

/**
 * Connects all blocks to their same-coloured neighbours.
 */
- (void)connectBlocks;

/**
 * Runs any logic on the blocks.  Should be called once per game iteration.
 * @return True if any blocks are still iterating.  False if not.
 */
- (BOOL)iterate;

/**
 * Adds the specified amount of garbage into the grid.  Garbage blocks are
 * placed into the shortest columns first.  If two or more columns have the same
 * height, garbage blocks are added into those columns in random order.
 * @param count The number of garbage blocks to add.
 */
- (void)addGarbage:(int)count;

/**
 * Gets the number of blocks that would be exploded if the specified block is
 * placed at the given co-ordinates.  No changes the the grid are made as the
 * block isn't actually placed.  This method allows the AI to determine the
 * efficacy of a given move.
 * @param x The x co-ordinate at which to place the block.
 * @param y The y co-ordinate at which to place the block.
 * @param block The block to place.
 * @param checkedData An array of booleans with the same dimensions as the grid.
 * Each element represents whether or not a particular grid location has already
 * been considered as part of a previous call to this method.  Therefore, any
 * blocks that correspond to a true value in this array are ignored, whilst any
 * blocks that correspond to a false value are considered for inclusion in the
 * block count.  Whenever a block is included in the block count its checkedData
 * value is set to true.
 * @return The number of blocks that would be exploded by placing the block.
 */
- (int)getPotentialExplodedBlockCount:(int)x y:(int)y block:(SZEggBase*)block checkedData:(BOOL*)checkedData;

/**
 * Gets the specified live block.  Valid indices are 0 and 1.
 * @param index The index of the live block to retrieve.
 * @return The specified live block.
 */
- (SZEggBase*)liveBlock:(int)index;

/**
 * Creates an array of points that represent grid co-ordinates of blocks that
 * are part of the chain of blocks that includes the specified co-ordinates.
 * @param x The x co-ordinate to start from.
 * @param y The y co-ordinate to start from.
 * @param checkedData An array of booleans with the same dimensions as the grid.
 * Each element represents whether or not a particular grid location has already
 * been considered as part of a chain due to a previous call to this method.
 * Therefore, any blocks that correspond to a true value in this array are
 * ignored, whilst any blocks that correspond to a false value are considered
 * for inclusion in the chain.  Whenever a block is included in a chain its
 * checkedData value is set to true.
 * @return A new array of points in the chain that includes the supplied
 * co-ordinates.
 */
- (NSMutableArray*)newPointChainFromCoordinatesX:(int)x y:(int)y checkedData:(BOOL*)checkedData;

/**
 * Gets an array of all arrays of block chains in the grid.
 * @return An array of all point chain arrays in the grid.
 */
- (NSMutableArray*)newPointChainsFromAllCoordinates;

/**
 * Creates the bottom row of blocks in the grid.  The bottom row is comprised of
 * non-functional blocks that look like they are part of the background but move
 * in response to being hit with garbage eggs.
 */
- (void)createBottomRow;

- (id)copy;
- (int)score;

@end
