#import "NormalBlock.h"

@implementation NormalBlock

- (void)connect:(EggBase*)top right:(EggBase*)right bottom:(EggBase*)bottom left:(EggBase*)left {
	
	BOOL topSet = top != NULL && [top class] == [self class] && top.state == SZEggStateNormal;
	BOOL rightSet = right != NULL && [right class] == [self class] && right.state == SZEggStateNormal;
	BOOL bottomSet = bottom != NULL && [bottom class] == [self class] && bottom.state == SZEggStateNormal;
	BOOL leftSet = left != NULL && [left class] == [self class] && left.state == SZEggStateNormal;
	
	[self setConnectionTop:topSet right:rightSet bottom:bottomSet left:leftSet];
}

@end
