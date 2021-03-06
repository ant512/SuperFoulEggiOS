#import <Foundation/NSArray.h>

#import "SZSmartAIController.h"

@implementation SZSmartAIController

- (id)initWithHesitation:(int)hesitation grid:(SZGrid *)grid {
	if ((self = [super init])) {
		_grid = [grid retain];
		_lastLiveEggY = SZGridHeight;
		_targetX = 0;
		_targetRotations = 0;
		_hesitation = hesitation;
	}
	
	return self;
}

- (void)dealloc {
	[_grid release];
	[super dealloc];
}

- (void)analyseGrid {
	
	SZEggBase *egg1 = [_grid liveEgg:0];
	SZEggBase *egg2 = [_grid liveEgg:1];
	
	// If last observed y is greater than current live egg y, we'll need
	// to choose a new move
	if (_lastLiveEggY <= egg1.y) {
		_lastLiveEggY = egg1.y < egg2.y ? egg1.y : egg2.y;

		return;
	}
	
	_lastLiveEggY = egg1.y < egg2.y ? egg1.y : egg2.y;
	
	int bestScore = INT_MIN;
	
	int *scores = malloc(sizeof(int) * SZGridWidth * 4);
	
	// We can multithread the AI so that it can analyse GRID_WIDTH * 4 grids
	// simultaneously.
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	
	dispatch_apply(SZGridWidth * 4, queue, ^(size_t i) {
		int x = i / 4;
		int rotation = i % 4;
			
		// Skip rotations 2 and 3 if eggs are the same colour, as they
		// are identical to rotations 0 and 1
		if ([egg1 isKindOfClass:[egg2 class]] && rotation > 1) {
			scores[i] = INT_MIN;
			return;
		}
		
		// Compensate for the fact that horizontal rotations can lead to us
		// checking illegal co-ordinates
		if (rotation == 0 && x >= SZGridWidth - 1) {
			scores[i] = INT_MIN;
			return;
		} else if (rotation == 2 && x >= SZGridWidth - 1) {
			scores[i] = INT_MIN;
			return;
		}
		
		scores[i] = [self scoreShapeX:x rotation:rotation];
	});
	
	for (int i = 0; i < SZGridWidth * 4; ++i) {

		int x = i / 4;
		int rotation = i % 4;
		
		// Check if the score for this position and rotation beats the
		// current best
		if (scores[i] > bestScore) {
			
			bestScore = scores[i];
			_targetX = x;
			_targetRotations = rotation;
		}
	}
	
	free(scores);
		
	// We can rotate to the correct orientation faster by rotating anticlockwise
	// if necessary
	if (_targetRotations == 3) _targetRotations = -1;
}

- (int)scoreShapeX:(int)x rotation:(int)rotation {

	int score = 0;
	int exploded = 0;
	int iteration = 1;
	
	SZGrid *gridCopy = [_grid copy];
	
	while (rotation > 0) {
		[gridCopy rotateLiveEggsClockwise];
		--rotation;
	}
	
	if ([gridCopy liveEgg:0].x > x) {
		while ([gridCopy liveEgg:0].x > x) {
			
			// Give up if the egg won't move
			if (![gridCopy moveLiveEggsLeft]) {
				[gridCopy release];
				return 0;
			}
		}
	} else if ([gridCopy liveEgg:0].x < x) {
		while ([gridCopy liveEgg:0].x < x) {
			
			// Give up if the egg won't move
			if (![gridCopy moveLiveEggsRight]) {
				[gridCopy release];
				return 0;
			}
		}
	}
	
	while (gridCopy.hasLiveEggs) [gridCopy dropLiveEggs];
	
	do {
		while ([gridCopy dropEggs]);
		while ([gridCopy iterate]);
	
		[gridCopy connectEggs];
	
		exploded = [gridCopy explodeEggs];
		while ([gridCopy iterate]);
		
		if (exploded > 0) {
			score += exploded << iteration;
			
			// Ensure a possible explosion is always favoured by setting the top
			// bit (not the sign bit)
			score = score | (1 << 30);
		} else {
			score += [gridCopy score] * iteration;
		}
		
		++iteration;
	} while (exploded > 0);
	
	// If the grid entry point is blocked, this move must have the lowest
	// priority possible
	if ([gridCopy eggAtX:2 y:0] != nil || [gridCopy eggAtX:3 y:0] != nil) {
		score = INT_MIN;
	}
	
	[gridCopy release];
	
	return score;
}

- (BOOL)isLeftHeld {
	[self analyseGrid];
	
	// We rotate before we move.  This can produce a situation at the top of the
	// grid wherein the AI rotates a egg and then can't move the rotated shape
	// to its chosen destination because another egg is in the way.  It
	// shouldn't really get into this situation because the moves are all
	// simulated, but it seems to do so anyway.  The AI will just bash the shape
	// up against the blocking area until it hits the bottom.  At this point in
	// a game it's probably a good thing that the AI can't recover or the hard
	// AI would be unbeatable.  I'm not going to fix the issue.
	if (_targetRotations != 0) return NO;
	
	SZEggBase *egg1 = [_grid liveEgg:0];
	
	BOOL result = egg1.x > _targetX;

	return _hesitation == 0 ? result : result && (rand() % _hesitation == 0);
}

- (BOOL)isRightHeld {
	[self analyseGrid];
	
	if (_targetRotations != 0) return NO;
	
	SZEggBase *egg1 = [_grid liveEgg:0];
	
	BOOL result = egg1.x < _targetX;

	return _hesitation == 0 ? result : result && (rand() % _hesitation == 0);
}

- (BOOL)isUpHeld {
	return NO;
}

- (BOOL)isDownHeld {
	[self analyseGrid];
	
	if (_targetRotations != 0) return NO;
	
	SZEggBase *egg1 = [_grid liveEgg:0];
	
	BOOL result = egg1.x == _targetX;
	
	return _hesitation == 0 ? result : result && (rand() % _hesitation == 0);
}

- (BOOL)isRotateClockwiseHeld {
	[self analyseGrid];
	
	if (_targetRotations > 0) {
		--_targetRotations;
		
		return YES;
	}
	
	return NO;
}

- (BOOL)isRotateAntiClockwiseHeld {
	[self analyseGrid];
	
	if (_targetRotations < 0) {
		++_targetRotations;
		
		return YES;
	}
	
	return NO;
}

@end
