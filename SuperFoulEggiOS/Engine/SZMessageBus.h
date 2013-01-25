#import <Foundation/Foundation.h>

@interface SZMessageBus : NSObject {
	NSMutableDictionary *_messageQueue;
}

+ (SZMessageBus *)sharedMessageBus;

- (void)sendGarbage:(int)count fromPlayerNumber:(int)from toPlayerNumber:(int)to;
- (NSDictionary *)nextMessageForPlayerNumber:(int)playerNumber;
- (void)removeNextMessageForPlayerNumber:(int)playerNumber;
- (BOOL)hasMessageForPlayerNumber:(int)playerNumber;

@end
