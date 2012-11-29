#import <Foundation/Foundation.h>

@class SZEggBase;

@protocol SZEggBaseDelegate <NSObject>

- (void)didEggStartExploding:(SZEggBase *)egg;
- (void)didEggStopExploding:(SZEggBase *)egg;
- (void)didEggStartLanding:(SZEggBase *)egg;
- (void)didEggStopLanding:(SZEggBase *)egg;
- (void)didEggStartFalling:(SZEggBase *)egg;
- (void)didEggMove:(SZEggBase *)egg;
- (void)didEggConnect:(SZEggBase *)egg;

@end

/**
 * Bitmask of possible connections.
 */
typedef NS_OPTIONS(NSUInteger, SZEggConnectionMask) {
	SZEggConnectionMaskNone = 0,			/**< No connections. */
	SZEggConnectionMaskTop = 1,				/**< Top connection. */
	SZEggConnectionMaskLeft = 2,			/**< Left connection. */
	SZEggConnectionMaskRight = 4,			/**< Right connection. */
	SZEggConnectionMaskBottom = 8			/**< Bottom connection. */
};

/**
 * List of all possible egg states.
 */
typedef NS_ENUM(NSUInteger, SZEggState) {
	SZEggStateNormal = 0,					/**< Egg is doing nothing. */
	SZEggStateFalling = 1,					/**< Egg is falling down the grid. */
	SZEggStateLanding = 2,					/**< Egg is landing. */
	SZEggStateExploding = 3,				/**< Egg is exploding. */
	SZEggStateExploded = 4,					/**< Egg has exploded. */
	SZEggStateRecoveringFromGarbageHit = 5	/**< Egg is adjusting back to its standard co-ords. */
};

/**
 * Base class for all eggs that appear in the grid.
 */
@interface SZEggBase : NSObject

@property (readwrite, assign) id <SZEggBaseDelegate> delegate;

/**
 * The x co-ordinate of the egg.
 */
@property (readonly) int x;

/**
 * The y co-ordinate of the egg.
 */
@property (readonly) int y;
		
/**
 * The current state of the egg.
 */
@property (readonly) SZEggState state;

/**
 * True if the egg has dropped half a grid square.
 */
@property (readonly) BOOL hasDroppedHalfBlock;

/**
 * Bitmask of active connections.
 */
@property (readonly) SZEggConnectionMask connections;

/**
 * Check if the egg is connected to the egg on its left.
 * @return True if a connection exists; false if not.
 */
- (BOOL)hasLeftConnection;

/**
 * Check if the egg is connected to the egg on its right.
 * @return True if a connection exists; false if not.
 */
- (BOOL)hasRightConnection;

/**
 * Check if the egg is connected to the egg above.
 * @return True if a connection exists; false if not.
 */
- (BOOL)hasTopConnection;

/**
 * Check if the egg is connected to the egg below.
 * @return True if a connection exists; false if not.
 */
- (BOOL)hasBottomConnection;

/**
 * Inform the egg that it is falling.
 */
- (void)startFalling;

/**
 * Inform the egg that it is exploding.
 */
- (void)startExploding;

/**
 * Inform the egg that it is no longer exploding.
 */
- (void)stopExploding;

/**
 * Inform the egg that it is landing.
 */
- (void)startLanding;

/**
 * Inform the egg that it is no longer landing.
 */
- (void)stopLanding;

/**
 * Inform the egg that it is recovering from being hit by garbage.
 */
- (void)startRecoveringFromGarbageHit;

/**
 * Inform the egg that it is no longer recovering from being hit by garbage.
 */
- (void)stopRecoveringFromGarbageHit;

/**
 * Inform the egg that it has dropped half a grid square.
 * @return True if the egg has dropped half a grid square.
 */
- (void)dropHalfBlock;

/**
 * Attempt to establish which of the surrounding eggs are of the same type as
 * this and remember those connections.
 * @param top The egg above this.
 * @param bottom The egg below this.
 * @param right The egg to the right of this.
 * @param left The egg to the left of this.
 */
- (void)connect:(SZEggBase*)top right:(SZEggBase*)right bottom:(SZEggBase*)bottom left:(SZEggBase*)left;

/**
 * Sets the connections that the egg has to the supplied parameters.
 * @param top The state of the top connection.
 * @param right The state of the right connection.
 * @param bottom The state of the bottom connection.
 * @param left The state of the left connection.
 */
- (void)setConnectionTop:(BOOL)top right:(BOOL)right bottom:(BOOL)bottom left:(BOOL)left;

/**
 * Sets the co-ordinates of the egg.  The co-ordinates should be changed every
 * time the egg is moved in the grid.
 * @param x The new x co-ordinate.
 * @param y The new y co-ordinate.
 */
- (void)setX:(int)x andY:(int)y;

@end
