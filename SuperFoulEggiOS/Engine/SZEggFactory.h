#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>

#import "SZEggBase.h"
#import "SZGrid.h"

typedef NS_ENUM(NSUInteger, SZEggColour) {
	SZEggColourNone = 0,
	SZEggColourRed = 1,
	SZEggColourBlue = 2,
	SZEggColourYellow = 3,
	SZEggColourPurple = 4,
	SZEggColourGreen = 5,
	SZEggColourOrange = 6,
	SZEggColourGarbage = 7,
};

/**
 * Each time a new set of eggs is added to a grid, the grid asks an instance
 * of this class for the eggs.  All grids must share the same SZEggFactory
 * instance.
 *
 * This class maintains an egg list and the position in the list of each player.
 * Thus, player 1 could request an egg.  If no eggs exist in the list a random
 * egg is added.  When player 2 requests an egg he will receive the egg
 * previously given to player 1.  If there are no more players in the list then
 * that egg is forgotten.  If there are more players, the egg is retained in the
 * list until all players have used it.  If player 1 requests 10 eggs whilst
 * player 2 is working on his first egg, the 9 egg between the two players are
 * retained until both players have used them.  This ensures that all players
 * are given the same set of eggs in the same order.
 */
@interface SZEggFactory : NSObject {
@private
	NSMutableArray *_eggList;		/**< List of egg classes that haven't been used by all players yet. */
	int *_playerEggListIndices;		/**< Each item in the array represents the index within
										 _eggList that each player is currently using. */
	int _eggColourCount;			/**< Number of colours that the factory can produce. */
	int _playerCount;				/**< Number of players in the game. */
	BOOL _isNetworkActive;
}

/**
 * Shared factory singleton instance.
 */
+ (SZEggFactory *)sharedFactory;

/**
 * Sets the player and egg colour counts and resets the factory.
 * @param playerCount The number of players in the game.
 * @param eggColourCount The number of egg colours available.
 */
- (void)setPlayerCount:(int)playerCount
		eggColourCount:(int)eggColourCount
	   isNetworkActive:(BOOL)isNetworkActive;

/**
 * Deallocates the object.
 */
- (void)dealloc;

/**
 * Clears all data in the SZEggFactory.
 */
- (void)clear;

- (BOOL)hasEggPairForPlayer:(int)playerNumber;

- (void)addEggPairFromColours:(NSArray *)eggColours;

/**
 * Creates and returns the next egg for the specified grid.
 * @param playerNumber The number of the player for whom the egg is being
 * created.
 * @return The next egg.
 */
- (SZEggBase *)newEggForPlayerNumber:(int)playerNumber;

/**
 * Adds a random egg class to the egg list.
 */
- (void)addRandomEggClass;

/**
 * Adds an egg class to the egg list based on the supplied colour.
 * @param colour Represents the type of egg class to add.
 */
- (void)addEggClassFromColour:(SZEggColour)colour;

/**
 * Removes all egg classes from the egg list that have been used by all players.
 */
- (void)expireUsedEggClasses;

/**
 * Returns a random egg class.
 * @return A random egg class.
 */
- (Class)randomEggClass;

- (SZEggColour)colourOfEgg:(SZEggBase *)egg;

@end
