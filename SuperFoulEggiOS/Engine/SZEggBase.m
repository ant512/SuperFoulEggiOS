#import "SZEggBase.h"

@implementation SZEggBase

- (id)init {
	if ((self = [super init])) {
		_state = SZEggStateNormal;
		_hasDroppedHalfBlock = NO;
		_connections = SZEggConnectionMaskNone;

		_x = -1;
		_y = -1;
	}

	return self;
}

- (void)dealloc {
	[_onStartExploding release];
	[_onStopExploding release];
	[_onStartLanding release];
	[_onStopLanding release];
	[_onStartFalling release];
	[_onMove release];
	[_onConnect release];
	[super dealloc];
}

- (BOOL)hasLeftConnection {
	return _connections & SZEggConnectionMaskLeft;
}

- (BOOL)hasRightConnection {
	return _connections & SZEggConnectionMaskRight;
}

- (BOOL)hasTopConnection {
	return _connections & SZEggConnectionMaskTop;
}

- (BOOL)hasBottomConnection {
	return _connections & SZEggConnectionMaskBottom;
}

- (void)startFalling {
	if (_state == SZEggStateFalling) return;
	
	//NSAssert(_state == BlockNormalState, @"Cannot make blocks fall that aren't in the normal state.");

	_state = SZEggStateFalling;
	_connections = SZEggConnectionMaskNone;

	if (_onStartFalling != nil) _onStartFalling(self);
}

- (void)stopExploding {
	NSAssert(_state == SZEggStateExploding, @"Cannot stop exploding blocks that aren't exploding.");

	_state = SZEggStateExploded;

	if (_onStopExploding != nil) _onStopExploding(self);
}

- (void)startExploding {
	
	if (_state == SZEggStateExploding) return;
	
	NSAssert(_state == SZEggStateNormal, @"Cannot explode blocks that aren't at rest.");
	
	_state = SZEggStateExploding;

	if (_onStartExploding != nil) {
		_onStartExploding(self);
	} else {
		// If we haven't got anything to listen to this event,
		// we need to force the block to explode automatically
		[self stopExploding];
	}
}

- (void)startLanding {

	NSAssert(_state == SZEggStateFalling, @"Cannot start landing blocks that aren't falling.");

	_state = SZEggStateLanding;

	if (_onStartLanding != nil) {
		_onStartLanding(self);
	} else {
		// If we haven't got anything to listen to this event,
		// we need to force the block to land automatically
		[self stopLanding];
	}
}

- (void)stopLanding {
	NSAssert(_state == SZEggStateLanding, @"Cannot stop landing blocks that aren't landing.");

	_state = SZEggStateNormal;

	if (_onStopLanding != nil) _onStopLanding(self);
}

- (void)startRecoveringFromGarbageHit {
	_state = SZEggStateRecoveringFromGarbageHit;
}

- (void)stopRecoveringFromGarbageHit {
	NSAssert(_state == SZEggStateRecoveringFromGarbageHit, @"Cannot stop a non-recovering block from recovering.");

	_state = SZEggStateNormal;
}

- (void)dropHalfBlock {
	_hasDroppedHalfBlock = !_hasDroppedHalfBlock;

	// Call the set co-ords method in order to trigger the movement event
	[self setX:_x andY:_y];
}

- (void)setConnectionTop:(BOOL)top right:(BOOL)right bottom:(BOOL)bottom left:(BOOL)left {
	_connections = top | (left << 1) | (right << 2) | (bottom << 3);

	if (_onConnect != nil) _onConnect(self);
}

- (void)connect:(SZEggBase*)top right:(SZEggBase*)right bottom:(SZEggBase*)bottom left:(SZEggBase*)left {
}

- (void)setX:(int)x andY:(int)y {

	_x = x;
	_y = y;

	if (_onMove != nil) _onMove(self);
}

@end