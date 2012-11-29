#import <Foundation/NSObject.h>

@protocol SZGameController <NSObject>

- (BOOL)isLeftHeld;
- (BOOL)isRightHeld;
- (BOOL)isUpHeld;
- (BOOL)isDownHeld;
- (BOOL)isRotateClockwiseHeld;
- (BOOL)isRotateAntiClockwiseHeld;

@end
