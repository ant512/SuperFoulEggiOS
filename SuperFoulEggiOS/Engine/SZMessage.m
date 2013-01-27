#import "SZMessage.h"

@implementation SZMessage

+ (SZMessage *)messageWithType:(SZMessageType)type
						  from:(int)from
							to:(int)to
						  info:(NSDictionary *)info {
	return [[[SZMessage alloc] initWithType:type
									   from:(int)from
										 to:(int)to
									   info:info] autorelease];
}

- (id)initWithType:(SZMessageType)type
			  from:(int)from
				to:(int)to
			  info:(NSDictionary *)info {
	if ((self = [super init])) {
		_type = type;
		_from = from;
		_to = to;
		_info = [info retain];
	}

	return self;
}

- (void)dealloc {
	[_info release];

	[super dealloc];
}

@end
