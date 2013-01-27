#import "SZEngineConstants.h"

const int SZGarbageFaceBoulderValue = 24;
const int SZGarbageLargeBoulderValue = 6;
const int SZEggSize = 48;
const int SZGridWidth = 6;
const int SZGridHeight = 16;
const int SZGridEntryY = 3;
const int SZChainLength = 4;

const int SZAutoDropTime = 2;
const int SZChainSequenceGarbageBonus = 6;
const int SZMaximumDropSpeed = 2;
const int SZMinimumDropSpeed = 38;
const int SZDropSpeedMultiplier = 4;

NSString * const SZRemoteMoveLeftNotification = @"SZRemoteMoveLeft";
NSString * const SZRemoteMoveRightNotification = @"SZRemoteMoveRight";
NSString * const SZRemoteMoveDownNotification = @"SZRemoteMoveDown";
NSString * const SZRemoteDropNotification = @"SZRemoteDrop";
NSString * const SZRemoteRotateClockwiseNotification = @"SZRemoteRotateClockwise";
NSString * const SZRemoteRotateAnticlockwiseNotification = @"SZRemoteRotateAnticlockwise";
NSString * const SZRemoteEggDeliveryNotification = @"SZRemoteEggDeliveryNotification";
NSString * const SZRemoteStartGameNotification = @"SZRemoteStartGameNotification";
NSString * const SZRemoteStartRoundNotification = @"SZRemoteStartRoundNotification";
NSString * const SZRemoteReadyForNextEggNotification = @"SZRemoteReadyForNextEggNotification";
