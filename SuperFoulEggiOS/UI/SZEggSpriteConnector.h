#import <Foundation/Foundation.h>

#import "cocos2d.h"
#import "SZEggBase.h"
#import "Grid.h"

#define BLOCK_EXPLODE_START_FRAME 16
#define BLOCK_EXPLODE_FRAME_COUNT 6
#define BLOCK_LAND_START_FRAME 22
#define BLOCK_LAND_FRAME_COUNT 7
#define BLOCK_ANIMATION_SPEED 2

@interface SZEggSpriteConnector : NSObject <SZEggBaseDelegate> {
@private
	int _timer;				/**< Used to control animations. */
	int _frame;				/**< Currently visible frame of animation. */
	int _yOffset;			/**< Offset from 0 of y co-ordinates, used when a garbage egg lands on top of this. */
}

/**
 * The egg in the grid that this connector joins with a sprite.
 */
@property(readonly, assign) SZEggBase* egg;

/**
 * The sprite on screen that this connector joins with an egg.
 */
@property(readonly, assign) CCSprite* sprite;

/**
 * If true, the egg is no longer in the grid and the connector needs to be
 * released.
 */
@property(readonly) BOOL isDead;

/**
 * The x co-ordinate of the grid that contains the object's egg.
 */
@property(readwrite) int gridX;

/**
 * The y co-ordinate of the grid that contains the object's egg.
 */
@property(readwrite) int gridY;

/**
 * Initialises a new instance of the class.
 * @param egg The egg in the grid that this connector joins with a sprite.
 * @param sprite The sprite on screen that this connector joins with a egg.
 * @param gridX The x co-ordinate of the grid that contains the object's egg.
 * @param gridY The y co-ordinate of the grid that contains the object's egg.
 */
- (id)initWithEgg:(SZEggBase*)egg sprite:(CCSprite*)sprite gridX:(int)gridX gridY:(int)gridY;

- (void)dealloc;
- (void)kill;
- (void)resetTimer;
- (void)resetYOffset;

/**
 * Updates the sprite to match the status of the egg.
 */
- (void)update;

/**
 * Sets the visible animation frame to the supplied value.
 * @param frame The frame to view.
 */
- (void)setSpriteFrame:(int)frame;

/**
 * Updates the sprite's position to match the egg's.
 */
- (void)updateSpritePosition;

/**
 * Offsets the y co-ordinate of the sprite to simulate the weight of the garbage
 * landing on it.
 */
- (void)hitWithGarbage;

@end
