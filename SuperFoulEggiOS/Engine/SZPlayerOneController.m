#import "SZPlayerOneController.h"
#import "SZPad.h"

@implementation SZPlayerOneController

- (BOOL)isLeftHeld {
	return [SZPad instanceOne].isLeftNewPress || [SZPad instanceOne].isLeftRepeat;
}

- (BOOL)isRightHeld {
	return [SZPad instanceOne].isRightNewPress || [SZPad instanceOne].isRightRepeat;
}

- (BOOL)isUpHeld {
	return [SZPad instanceOne].isUpNewPress || [SZPad instanceOne].isUpRepeat;
}

- (BOOL)isDownHeld {
	return [SZPad instanceOne].isDownHeld;
}

- (BOOL)isRotateClockwiseHeld {
	return [SZPad instanceOne].isANewPress;
}

- (BOOL)isRotateAntiClockwiseHeld {
	return [SZPad instanceOne].isBNewPress;
}

@end
