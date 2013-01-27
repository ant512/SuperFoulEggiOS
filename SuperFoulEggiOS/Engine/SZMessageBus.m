#import "SZMessageBus.h"
#import "SZMessage.h"
#import "SZNetworkSession.h"

@implementation SZMessageBus

+ (SZMessageBus *)sharedMessageBus {
	static SZMessageBus *sharedBus = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		sharedBus = [[SZMessageBus alloc] init];
	});

	return sharedBus;
}

- (id)init {
	if ((self = [super init])) {
		_messageQueues = [[NSMutableDictionary dictionary] retain];
	}

	return self;
}

- (void)dealloc {
	[_messageQueues release];

	[super dealloc];
}

- (void)sendGarbage:(int)count fromPlayerNumber:(int)from toPlayerNumber:(int)to {
	NSMutableArray *queue = [self messageQueueForPlayerNumber:to];
	
	@synchronized(queue) {
		[queue addObject:[SZMessage messageWithType:SZMessageTypeGarbage
											   from:from
												 to:to
											   info:@{ @"Count": @(count) }]];
	}
}

- (void)sendBlockMove:(SZBlockMoveType)move fromPlayerNumber:(int)from {
	[[SZNetworkSession sharedSession] sendBlockMove:move fromPlayerNumber:from];
}

- (void)sendPlaceNextEggsFromPlayerNumber:(int)from {
	[[SZNetworkSession sharedSession] sendPlaceNextEggsFromPlayerNumber:from];
}

- (NSMutableArray *)messageQueueForPlayerNumber:(int)playerNumber {

	@synchronized(_messageQueues) {
	
		NSString *key = [NSString stringWithFormat:@"%d", playerNumber];
		NSMutableArray *queue = _messageQueues[key];

		if (!queue) {
			queue = [NSMutableArray array];
			_messageQueues[key] = queue;
		}

		return queue;
	}
}

- (void)removeNextMessageForPlayerNumber:(int)playerNumber {
	
	if (![self hasMessageForPlayerNumber:playerNumber]) return;

	NSMutableArray *queue = [self messageQueueForPlayerNumber:playerNumber];
	
	@synchronized(queue) {
		[queue removeObjectAtIndex:0];
	}
}

- (BOOL)hasMessageForPlayerNumber:(int)playerNumber {
	
	NSMutableArray *queue = [self messageQueueForPlayerNumber:playerNumber];
	
	@synchronized(queue) {
		if (!queue) return false;
		if (queue.count == 0) return false;
	}

	return true;
}

- (SZMessage *)nextMessageForPlayerNumber:(int)playerNumber {

	if (![self hasMessageForPlayerNumber:playerNumber]) return nil;
	
	NSMutableArray *queue = [self messageQueueForPlayerNumber:playerNumber];
	
	@synchronized(queue) {
		SZMessage *message = [[[queue objectAtIndex:0] retain] autorelease];
		[queue removeObjectAtIndex:0];
		return message;
	}
}

- (void)receiveMessage:(SZMessage *)message {
	NSMutableArray *queue = [self messageQueueForPlayerNumber:message.to];
	
	@synchronized(queue) {
		[queue addObject:message];
	}
}

@end
