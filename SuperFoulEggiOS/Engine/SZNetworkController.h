#import <Foundation/Foundation.h>
#import "SZGameController.h"

@interface SZNetworkController : NSObject <SZGameController> {
	NSMutableArray *_queuedMoves;
}

@end
