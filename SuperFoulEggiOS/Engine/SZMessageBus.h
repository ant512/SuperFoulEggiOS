#import <Foundation/Foundation.h>

@class SZMessage;

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
- (SZMessage *)nextMessageForPlayerNumber:(int)playerNumber;
- (void)removeNextMessageForPlayerNumber:(int)playerNumber;
- (BOOL)hasMessageForPlayerNumber:(int)playerNumber;

@end
