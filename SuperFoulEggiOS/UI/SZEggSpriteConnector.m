#import "SZEggSpriteConnector.h"

#define SZEggLandFrameCount 7

const int SZEggExplodeStartFrame = 16;
const int SZEggExplodeFrameCount = 6;
const int SZEggLandStartFrame = 22;
const int SZEggAnimationSpeed = 2;

@implementation SZEggSpriteConnector

- (id)initWithEgg:(SZEggBase*)egg sprite:(CCSprite*)sprite gridX:(int)gridX gridY:(int)gridY {
	if ((self = [super init])) {
		_egg = [egg retain];
		_sprite = [sprite retain];
		_isDead = NO;
		_timer = 0;
		_yOffset = 0;
		_gridX = gridX;
		_gridY = gridY;

		[self updateSpritePosition];
		[self setSpriteFrame:0];

		egg.delegate = self;
	}

	return self;
}

- (void)kill {
	[_sprite.parent removeChild:_sprite cleanup:YES];
	
	[_sprite release];
	[_egg release];
	
	_sprite = nil;
	_egg = nil;
	
	_isDead = YES;
}

- (void)resetTimer {
	_timer = 0;
}

- (void)resetYOffset {
	_yOffset = 0;
}


- (void)didEggConnect:(SZEggBase *)egg {
	[self setSpriteFrame:egg.connections];
}

- (void)didEggMove:(SZEggBase *)egg {
	[self updateSpritePosition];
}

- (void)didEggStartExploding:(SZEggBase *)egg {
	[self resetTimer];
}

- (void)didEggStopExploding:(SZEggBase *)egg {
	[self kill];
}

- (void)didEggStartFalling:(SZEggBase *)egg {
	
	// Prevent eggs in the grid from being displaced if their garbage
	// hit bounce is interrupted
	[self resetYOffset];

	[self setSpriteFrame:egg.connections];
}

- (void)didEggStartLanding:(SZEggBase *)egg {
	[self resetTimer];

	[self setSpriteFrame:SZEggLandStartFrame];
}

- (void)didEggStopLanding:(SZEggBase *)egg {
}

- (void)dealloc {
	[_sprite removeFromParentAndCleanup:YES];
	[_sprite release];
	[_egg release];
	[super dealloc];
}

- (void)updateSpritePosition {

	// Co-ords are adjusted so that the sprite is relative to the containing
	// grid
	int x = _gridX + (_egg.x * SZEggSize) + (SZEggSize / 2);
	int y = _gridY + (SZGridHeight * SZEggSize) - (SZEggSize / 2) - ((_egg.y * SZEggSize) + _yOffset);

	// Add an extra half egg's height if the egg has fallen a half block
	y -= _egg.hasDroppedHalfBlock ? SZEggSize / 2 : 0;

	_sprite.position = ccp(x, y);
}

- (void)setSpriteFrame:(int)frame {
	[_sprite setTextureRect:CGRectMake((frame % 5) * SZEggSize, (frame / 5) * SZEggSize, SZEggSize, SZEggSize)];
	_frame = frame;
}

- (void)update {

	switch (_egg.state) {
		case SZEggStateExploding:

			// The egg is exploding.  We run through the frames of explosion
			// animation each time this method is called until we run out of
			// frames, whereupon we tell the egg that it has finished
			// exploding.  The egg's explosion stopped event will fire and
			// this object and its components will eventually be deallocated

			if (_timer % SZEggAnimationSpeed == 0) {
				
				if (_frame < SZEggExplodeStartFrame || _frame >= SZEggExplodeStartFrame + SZEggExplodeFrameCount) {
					[self setSpriteFrame:SZEggExplodeStartFrame];
				} else if (_frame == SZEggExplodeStartFrame + SZEggExplodeFrameCount - 1) {

					// Reached the end of the explosion frames
					[_egg stopExploding];
				} else {

					// Move to the next explosion frame
					[self setSpriteFrame:_frame + 1];
				}
			}
			
			++_timer;
			
			break;

		case SZEggStateLanding:

			// The egg is landing.  We run through the animation until we run
			// out of frames.  At that point, the egg is told that it is no
			// longer landing.

			if (_timer == SZEggLandFrameCount * SZEggAnimationSpeed) {

				// Reached the end of the landing animation, so tell the egg it
				// has finished landing
				[_egg stopLanding];
			} else if (_timer % SZEggAnimationSpeed == 0) {

				// List of landing animation frames
				static int landingSequence[SZEggLandFrameCount] = { 0, 22, 23, 22, 23, 22, 0 };

				// Move to the frame appropriate to the current timer
				[self setSpriteFrame:landingSequence[_timer / SZEggAnimationSpeed]];
			}
			
			++_timer;
			
			break;
		
		case SZEggStateRecoveringFromGarbageHit:

			// Egg has been hit by a garbage egg from above and is being eased
			// back to its correct position.
			
			if (_timer % 2 == 0) {
				
				if (_timer < 16) {
				
					static int offsets[8] = { 8, 2, -4, 6, -3, 1, -1, 0 };
					
					_yOffset = offsets[_timer / 2];
				} else {
					[_egg stopRecoveringFromGarbageHit];
				}
			
				[self updateSpritePosition];
			}
			
			++_timer;

			break;

		default:

			// Egg isn't doing anything interesting
			break;
	}
}

- (void)hitWithGarbage {
	if (_egg.state != SZEggStateNormal && _egg.state != SZEggStateLanding && _egg.state != SZEggStateRecoveringFromGarbageHit) return;
	
	_timer = 0;

	[_egg startRecoveringFromGarbageHit];
}

@end
