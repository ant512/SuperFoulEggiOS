#import <Foundation/Foundation.h>

@class SZMessage;

typedef NS_ENUM(NSUInteger, SZBlockMoveType) {
	SZBlockMoveTypeLeft = 0,
	SZBlockMoveTypeRight = 1,
	SZBlockMoveTypeDown = 2,
	SZBlockMoveTypeRotateClockwise = 3,
	SZBlockMoveTypeRotateAnticlockwise = 4
};

/**
 * Allows for communication between different SZGridRunner instances.  Each
 * player has his own message queue, which is stored in a dictionary using the
 * player number as the key.  Each program loop, the grids must check for
 * incoming messages, remove them, and process them appropriately.
 */
@interface SZMessageBus : NSObject {
	NSMutableDictionary *_messageQueues;	/**< All message queues. */
}

+ (SZMessageBus *)sharedMessageBus;

- (void)sendGarbage:(int)count fromPlayerNumber:(int)from toPlayerNumber:(int)to;
- (void)sendBlockMove:(SZBlockMoveType)move fromPlayerNumber:(int)from;

- (void)receiveMessage:(SZMessage *)message;

- (SZMessage *)nextMessageForPlayerNumber:(int)playerNumber;
- (void)removeNextMessageForPlayerNumber:(int)playerNumber;
- (BOOL)hasMessageForPlayerNumber:(int)playerNumber;

@end
