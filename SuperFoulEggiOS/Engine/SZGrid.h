#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>

#import "SZEggBase.h"
#import "SZGridBase.h"
#import "SZEngineConstants.h"

@class SZGrid;
@class SZEggBase;

@protocol SZGridDelegate <NSObject>
@required

- (void)didLandEggInGrid:(SZGrid *)grid;
- (void)didLandGarbageEggInGrid:(SZGrid *)grid;
- (void)didAddGarbageEggRowToGrid:(SZGrid *)grid;

- (void)grid:(SZGrid *)grid didLandGarbageEgg:(SZEggBase *)egg;
- (void)grid:(SZGrid *)grid didAddEgg:(SZEggBase *)egg;

@optional

- (void)grid:(SZGrid *)grid didRemoveEgg:(SZEggBase *)egg;

@end

/**
 * Extends the GridBase class with events that fire whenever anything
 * interesting happens, and a set of game-specific functions for manipulating
 * the eggs.
 */
@interface SZGrid : SZGridBase {
@private
	SZEggBase *_liveEggs[SZLiveEggCount];	/**< The co-ordinates of the two live eggs in the grid. */
}

@property (readwrite, assign) id <SZGridDelegate> delegate;

/**
 * Check if the grid has live eggs.
 */
@property (readonly) BOOL hasLiveEggs;

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
 * Add an egg to the grid.  The grid assumes ownership of the egg.
 * @param x The x co-ordinate of the egg.
 * @param y The y co-ordinate of the egg.
 */
- (void)addEgg:(SZEggBase *)egg x:(int)x y:(int)y;

/**
 * Removes and deallocates the egg at the specified co-ordinates.
 * @param x The x co-ordinate of the egg to remove.
 * @param y The y co-ordinate of the egg to remove.
 */
- (void)removeEggAtX:(int)x y:(int)y;

/**
 * Explodes all eligible chains of eggs in the grid.
 * @return The number of eggs exploded.
 */
- (int)explodeEggs;

/**
 * Drops the live eggs down half of one square.
 * @return YES if the eggs dropped; no if at least one landed.
 */
- (BOOL)dropLiveEggs;

/**
 * Drops all eggs down half of one square.
 * @return True if any eggs drop; false if not.
 */
- (BOOL)dropEggs;

/**
 * Attempts to move the live eggs one square to the left.
 * @return True if the move was successful; false if not.
 */
- (BOOL)moveLiveEggsLeft;

/**
 * Attempts to move the live eggs one square to the right.
 * @return True if the move was successful; false if not.
 */
- (BOOL)moveLiveEggsRight;

/**
 * Attempts to rotate the live eggs clockwise.
 * @return True if the rotation was successful; false if not.
 */
- (BOOL)rotateLiveEggsClockwise;

/**
 * Attempts to rotate the live eggs anti-clockwise.
 * @return True if the rotation was successful; false if not.
 */
- (BOOL)rotateLiveEggsAntiClockwise;

/**
 * Attempts to add the specified eggs to the grid as new live eggs.  The
 * grid assumes ownership of the eggs.
 * @param egg1 The left-hand egg in the new live pair.
 * @param egg2 The right-hand egg in the new live pair.
 * @return True if the eggs were added; false if they could not be added.
 * Failure indicates game over.
 */
- (BOOL)addLiveEggs:(SZEggBase *)egg1 egg2:(SZEggBase *)egg2;

/**
 * Connects all eggs to their same-coloured neighbours.
 */
- (void)connectEggs;

/**
 * Runs any logic on the eggs.  Should be called once per game iteration.
 * @return True if any eggs are still iterating.  False if not.
 */
- (BOOL)iterate;

/**
 * Adds the specified amount of garbage into the grid.  Garbage eggs are
 * placed into the shortest columns first.  If two or more columns have the same
 * height, garbage eggs are added into those columns in random order.
 * @param count The number of garbage eggs to add.
 */
- (void)addGarbage:(int)count randomPlacement:(BOOL)randomPlacement;

/**
 * Gets the number of eggs that would be exploded if the specified egg is
 * placed at the given co-ordinates.  No changes the the grid are made as the
 * egg isn't actually placed.  This method allows the AI to determine the
 * efficacy of a given move.
 * @param x The x co-ordinate at which to place the egg.
 * @param y The y co-ordinate at which to place the egg.
 * @param egg The egg to place.
 * @param checkedData An array of booleans with the same dimensions as the grid.
 * Each element represents whether or not a particular grid location has already
 * been considered as part of a previous call to this method.  Therefore, any
 * eggs that correspond to a true value in this array are ignored, whilst any
 * eggs that correspond to a false value are considered for inclusion in the
 * egg count.  Whenever an egg is included in the egg count its checkedData
 * value is set to true.
 * @return The number of eggs that would be exploded by placing the egg.
 */
- (int)getPotentialExplodedEggCount:(int)x y:(int)y egg:(SZEggBase *)egg checkedData:(BOOL *)checkedData;

/**
 * Gets the specified live egg.  Valid indices are 0 and 1.
 * @param index The index of the live egg to retrieve.
 * @return The specified live egg.
 */
- (SZEggBase *)liveEgg:(int)index;

/**
 * Creates an array of points that represent grid co-ordinates of eggs that
 * are part of the chain of eggs that includes the specified co-ordinates.
 * @param x The x co-ordinate to start from.
 * @param y The y co-ordinate to start from.
 * @param checkedData An array of booleans with the same dimensions as the grid.
 * Each element represents whether or not a particular grid location has already
 * been considered as part of a chain due to a previous call to this method.
 * Therefore, any eggs that correspond to a true value in this array are
 * ignored, whilst any eggs that correspond to a false value are considered
 * for inclusion in the chain.  Whenever an egg is included in a chain its
 * checkedData value is set to true.
 * @return A new array of points in the chain that includes the supplied
 * co-ordinates.
 */
- (NSMutableArray *)newPointChainFromCoordinatesX:(int)x y:(int)y checkedData:(BOOL *)checkedData;

/**
 * Gets an array of all arrays of egg chains in the grid.
 * @return An array of all point chain arrays in the grid.
 */
- (NSMutableArray *)newPointChainsFromAllCoordinates;

/**
 * Creates the bottom row of eggs in the grid.  The bottom row is comprised of
 * non-functional eggs that look like they are part of the background but move
 * in response to being hit with garbage eggs.
 */
- (void)createBottomRow;

- (id)copy;
- (int)score;

@end
