#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SZMessageType) {
	SZMessageTypeGarbage = 0
};

@interface SZMessage : NSObject

+ (SZMessage *)messageWithType:(SZMessageType)type info:(NSDictionary *)info;

@property (readonly, nonatomic) SZMessageType type;
@property (readonly) NSDictionary *info;

@end
