#import "SZMessageBus.h"
#import "SZMessage.h"

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

	[queue addObject:[SZMessage messageWithType:SZMessageTypeGarbage info:@{ @"Count": @(count) }]];
}

- (NSMutableArray *)messageQueueForPlayerNumber:(int)playerNumber {

	NSString *key = [NSString stringWithFormat:@"%d", playerNumber];
	NSMutableArray *queue = _messageQueues[key];

	if (!queue) {
		queue = [NSMutableArray array];
		_messageQueues[key] = queue;
	}

	return queue;
}

- (void)removeNextMessageForPlayerNumber:(int)playerNumber {
	
	if (![self hasMessageForPlayerNumber:playerNumber]) return;

	NSMutableArray *queue = [self messageQueueForPlayerNumber:playerNumber];

	[queue removeObjectAtIndex:0];
}

- (BOOL)hasMessageForPlayerNumber:(int)playerNumber {
	
	NSMutableArray *queue = [self messageQueueForPlayerNumber:playerNumber];

	if (!queue) return false;
	if (queue.count == 0) return false;

	return true;
}

- (SZMessage *)nextMessageForPlayerNumber:(int)playerNumber {

	if (![self hasMessageForPlayerNumber:playerNumber]) return nil;
	
	NSMutableArray *queue = [self messageQueueForPlayerNumber:playerNumber];

	SZMessage *message = [[[queue objectAtIndex:0] retain] autorelease];

	[queue removeObjectAtIndex:0];

	return message;
}

@end
