#import <Foundation/NSObject.h>

#import "SZEggBase.h"

#define GRID_WIDTH 6
#define GRID_HEIGHT 16
#define GRID_SIZE 96
#define GRID_ENTRY_Y 3

/**
 * Maintains the list of blocks that make up the playing grid.
 */
@interface GridBase : NSObject {
@private
	SZEggBase* _data[GRID_SIZE];	/**< The array of blocks that constitutes the grid. */
}

/**
 * Clears the grid of all blocks.
 */
- (void)clear;

/**
 * Gets the egg at the specified co-ordinates.
 * @param x The x co-ordinate of the egg to retrieve.
 * @param y The y co-ordinate of the egg to retrieve.
 */
- (SZEggBase*)eggAtX:(int)x y:(int)y;

/**
 * Add an egg to the grid.  The grid assumes ownership of the egg.
 * @param x The x co-ordinate of the egg.
 * @param y The y co-ordinate of the egg.
 */
- (void)addEgg:(SZEggBase*)egg x:(int)x y:(int)y;

/**
 * Removes and deallocates the egg at the specified co-ordinates.
 * @param x The x co-ordinate of the egg to remove.
 * @param y The y co-ordinate of the egg to remove.
 */
- (void)removeEggAtX:(int)x y:(int)y;

/**
 * Gets the height of the specified column.
 * @param index The column index.
 * @return The height of the column.
 */
- (int)heightOfColumnAtIndex:(int)index;

/**
 * Moves the egg at the specified source co-ordinates to the destination
 * co-ordinates.
 * @param sourceX The source x co-ordinate.
 * @param sourceY The source y co-ordinate.
 * @param destinationX The destination x co-ordinate.
 * @param destinationY The destination y co-ordinate.
 */
- (void)moveEggFromSourceX:(int)sourceX sourceY:(int)sourceY toDestinationX:(int)destinationX destinationY:(int)destinationY;

/**
 * Checks if the specified co-ordinates fall inside the grid.
 * @param x The x co-ordinate to check.
 * @param y The y co-ordinate to check.
 * @return True if the co-ordinates are valid; false if not.
 */
- (BOOL)isValidCoordinateX:(int)x y:(int)y;

@end
