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

	_state = SZEggStateFalling;
	_connections = SZEggConnectionMaskNone;

	[_delegate didEggStartFalling:self];
}

- (void)stopExploding {
	NSAssert(_state == SZEggStateExploding, @"Cannot stop exploding eggs that aren't exploding.");

	_state = SZEggStateExploded;

	[_delegate didEggStopExploding:self];
}

- (void)startExploding {
	
	if (_state == SZEggStateExploding) return;
	
	NSAssert(_state == SZEggStateNormal, @"Cannot explode eggs that aren't at rest.");
	
	_state = SZEggStateExploding;

	if (_delegate) {
		[_delegate didEggStartExploding:self];
	} else {
		[self stopExploding];
	}
}

- (void)startLanding {

	NSAssert(_state == SZEggStateFalling, @"Cannot start landing eggs that aren't falling.");

	_state = SZEggStateLanding;

	if (_delegate) {
		[_delegate didEggStartLanding:self];
	} else {
		[self stopLanding];
	}
}

- (void)stopLanding {
	NSAssert(_state == SZEggStateLanding, @"Cannot stop landing eggs that aren't landing.");

	_state = SZEggStateNormal;

	[_delegate didEggStopLanding:self];
}

- (void)startRecoveringFromGarbageHit {
	_state = SZEggStateRecoveringFromGarbageHit;
}

- (void)stopRecoveringFromGarbageHit {
	NSAssert(_state == SZEggStateRecoveringFromGarbageHit, @"Cannot stop a non-recovering egg from recovering.");

	_state = SZEggStateNormal;
}

- (void)dropHalfBlock {
	_hasDroppedHalfBlock = !_hasDroppedHalfBlock;

	// Call the set co-ords method in order to trigger the movement event
	[self setX:_x andY:_y];
}

- (void)setConnectionTop:(BOOL)top right:(BOOL)right bottom:(BOOL)bottom left:(BOOL)left {
	_connections = top | (left << 1) | (right << 2) | (bottom << 3);

	[_delegate didEggConnect:self];
}

- (void)connect:(SZEggBase *)top right:(SZEggBase *)right bottom:(SZEggBase *)bottom left:(SZEggBase *)left {
}

- (void)setX:(int)x andY:(int)y {

	_x = x;
	_y = y;

	[_delegate didEggMove:self];
}

@end
