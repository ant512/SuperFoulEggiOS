#import "SZMessage.h"

@implementation SZMessage

+ (SZMessage *)messageWithType:(SZMessageType)type info:(NSDictionary *)info {
	return [[[SZMessage alloc] initWithType:type info:info] autorelease];
}

- (id)initWithType:(SZMessageType)type info:(NSDictionary *)info {
	if ((self = [super init])) {
		_type = type;
		_info = [info retain];
	}

	return self;
}

- (void)dealloc {
	[_info release];

	[super dealloc];
}

@end
