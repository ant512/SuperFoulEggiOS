#import <Foundation/NSObject.h>

#import "SZGameController.h"
#import "SZGrid.h"
#import "SZEggBase.h"
#import "SZPoint.h"

/**
 * Artificial intelligence controller.  Analyses the state of the grid it is
 * controlling in order to determine what action to take next.
 */
@interface SZSmartAIController : NSObject <SZGameController> {
	SZGrid *_grid;				/**< The Grid that the AI is controlling. */
	int _lastLiveEggY;			/**< The last observed y co-ordinate of the first live egg. */
	int _targetX;				/**< The x co-ordinate the AI is trying to move the live egg to. */
	int _targetRotations;		/**< Number of clockwise rotations needed before correct live egg
									 orientation is achieved. */
	int _hesitation;			/**< Chance that the AI will hesitate (larger value = more likely;
									 0 = no hesitation). */
}

/**
 * Initialises a new instance of the class.
 * @param hesitation The chance of the AI hesitating when given the option to
 * make a move.  A high value makes the AI being slower.  A low value makes the
 * AI faster.
 * @param grid The grid that the AI will control.
 */
- (id)initWithHesitation:(int)hesitation grid:(SZGrid *)grid;

/**
 * Deallocates the instance.
 */
- (void)dealloc;

/**
 * Analyses the state of the grid and determines what action to take.  Called
 * every time the AI has the opportunity to move, but the grid is only analysed
 * when a new pair of eggs has been added to the grid.  The analysis is very
 * simple.  For every possible end position for this pair (every location and
 * rotation that the pair can end up in when they land), score the position.
 * Score is simply the number of eggs that connect to the landed live egg.
 * Choose the best position and remember the rotation/location.  Whenever the
 * opportunity to move is given, move towards the desired position.
 */
- (void)analyseGrid;

/**
 * Determines the score obtained by placing the current shape at the given x
 * co-ordinate using the specified rotation.
 * @param x The x co-ordinate for the shape.
 * @param rotation The rotation of the shape.
 * @return The score for the co-ordinate/rotation pair.
 */
- (int)scoreShapeX:(int)x rotation:(int)rotation;


/**
 * Is left held?
 */
- (BOOL)isLeftHeld;

/**
 * Is right held?
 */
- (BOOL)isRightHeld;

/**
 * Is up held?
 */
- (BOOL)isUpHeld;

/**
 * Is down held?
 */
- (BOOL)isDownHeld;

/**
 * Is the rotate clockwise button held?
 */
- (BOOL)isRotateClockwiseHeld;

/**
 * Is the rotate anticlockwise button held?
 */
- (BOOL)isRotateAntiClockwiseHeld;

@end
