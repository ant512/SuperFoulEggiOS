#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SZMessageType) {
	SZMessageTypeGarbage = 0,
	SZMessageTypeMove = 1,
	SZMessageTypePlaceNextEggs = 2,
	SZMessageTypeState = 3
};

@interface SZMessage : NSObject

+ (SZMessage *)messageWithType:(SZMessageType)type
						  from:(int)from
							to:(int)to
						  info:(NSDictionary *)info;

@property (readonly) SZMessageType type;
@property (readonly) int from;
@property (readonly) int to;
@property (readonly) NSDictionary *info;

@end
