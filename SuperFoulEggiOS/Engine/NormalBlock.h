#import "EggBase.h"

@interface NormalBlock : EggBase {

}

- (void)connect:(EggBase*)top right:(EggBase*)right bottom:(EggBase*)bottom left:(EggBase*)left;

@end
