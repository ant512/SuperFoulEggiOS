#import "PlayerTwoController.h"
#import "SZPad.h"

@implementation PlayerTwoController

- (BOOL)isLeftHeld {
	return [SZPad instanceTwo].isLeftNewPress || [SZPad instanceTwo].isLeftRepeat;
}

- (BOOL)isRightHeld {
	return [SZPad instanceTwo].isRightNewPress || [SZPad instanceTwo].isRightRepeat;
}

- (BOOL)isUpHeld {
	return [SZPad instanceTwo].isUpNewPress || [SZPad instanceTwo].isUpRepeat;
}

- (BOOL)isDownHeld {
	return [SZPad instanceTwo].isDownHeld;
}

- (BOOL)isRotateClockwiseHeld {
	return [SZPad instanceTwo].isANewPress;
}

- (BOOL)isRotateAntiClockwiseHeld {
	return [SZPad instanceTwo].isBNewPress;
}

@end
