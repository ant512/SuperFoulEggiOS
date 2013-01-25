#import <Foundation/Foundation.h>

@class SZMessage;

@interface SZMessageBus : NSObject {
	NSMutableDictionary *_messageQueue;
}

+ (SZMessageBus *)sharedMessageBus;

- (void)sendGarbage:(int)count fromPlayerNumber:(int)from toPlayerNumber:(int)to;
- (SZMessage *)nextMessageForPlayerNumber:(int)playerNumber;
- (void)removeNextMessageForPlayerNumber:(int)playerNumber;
- (BOOL)hasMessageForPlayerNumber:(int)playerNumber;

@end
