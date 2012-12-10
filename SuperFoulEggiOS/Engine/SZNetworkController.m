#import "SZNetworkController.h"
#import "SZEngineConstants.h"

typedef NS_ENUM(NSUInteger, SZNetworkControllerQueuedMoveType) {
	SZNetworkControllerQueuedMoveTypeNone = 0,
	SZNetworkControllerQueuedMoveTypeLeft = 1,
	SZNetworkControllerQueuedMoveTypeRight = 2,
	SZNetworkControllerQueuedMoveTypeDown = 3,
	SZNetworkControllerQueuedMoveTypeRotateClockwise = 4,
	SZNetworkControllerQueuedMoveTypeRotateAnticlockwise = 5
};

@implementation SZNetworkController

- (id)init {
	if ((self = [super init])) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRemoteMoveLeft) name:SZRemoteMoveLeftNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRemoteMoveRight) name:SZRemoteMoveRightNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRemoteDrop) name:SZRemoteDropNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRemoteRotateClockwise) name:SZRemoteRotateClockwiseNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRemoteRotateAnticlockwise) name:SZRemoteRotateAnticlockwiseNotification object:nil];

		_queuedMoves = [[NSMutableArray array] retain];
	}

	return self;
}

- (void)dealloc {
	[_queuedMoves release];

	[[NSNotificationCenter defaultCenter] removeObserver:self name:SZRemoteMoveLeftNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:SZRemoteMoveRightNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:SZRemoteDropNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:SZRemoteRotateClockwiseNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:SZRemoteRotateAnticlockwiseNotification object:nil];
	
	[super dealloc];
}

- (void)receiveRemoteMoveLeft {
	[_queuedMoves addObject:@(SZNetworkControllerQueuedMoveTypeLeft)];
}

- (void)receiveRemoteMoveRight {
	[_queuedMoves addObject:@(SZNetworkControllerQueuedMoveTypeRight)];
}

- (void)receiveRemoteDrop {
	[_queuedMoves addObject:@(SZNetworkControllerQueuedMoveTypeDown)];
}

- (void)receiveRemoteRotateClockwise {
	[_queuedMoves addObject:@(SZNetworkControllerQueuedMoveTypeRotateClockwise)];
}

- (void)receiveRemoteRotateAnticlockwise {
	[_queuedMoves addObject:@(SZNetworkControllerQueuedMoveTypeRotateAnticlockwise)];
}

- (BOOL)isLeftHeld {
	if ([_queuedMoves[0] intValue] == SZNetworkControllerQueuedMoveTypeLeft) {
		[_queuedMoves removeObjectAtIndex:0];

		return YES;
	}

	return NO;
}

- (BOOL)isRightHeld {
	if ([_queuedMoves[0] intValue] == SZNetworkControllerQueuedMoveTypeRight) {
		[_queuedMoves removeObjectAtIndex:0];

		return YES;
	}

	return NO;
}

- (BOOL)isUpHeld {
	return NO;
}

- (BOOL)isDownHeld {
	if ([_queuedMoves[0] intValue] == SZNetworkControllerQueuedMoveTypeDown) {
		[_queuedMoves removeObjectAtIndex:0];

		return YES;
	}

	return NO;
}

- (BOOL)isRotateClockwiseHeld {
	if ([_queuedMoves[0] intValue] == SZNetworkControllerQueuedMoveTypeRotateClockwise) {
		[_queuedMoves removeObjectAtIndex:0];

		return YES;
	}

	return NO;
}

- (BOOL)isRotateAntiClockwiseHeld {
	if ([_queuedMoves[0] intValue] == SZNetworkControllerQueuedMoveTypeRotateAnticlockwise) {
		[_queuedMoves removeObjectAtIndex:0];

		return YES;
	}

	return NO;
}

@end
