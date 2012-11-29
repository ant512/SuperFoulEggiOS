#import <Foundation/Foundation.h>

#import "SZGrid.h"
#import "SZGarbageEgg.h"
#import "SZGridBottomEgg.h"
#import "SZGridBottomLeftEgg.h"
#import "SZGridBottomRightEgg.h"
#import "SZPoint.h"
#import "SZEngineConstants.h"

@implementation SZGrid

- (id)initWithPlayerNumber:(int)playerNumber {
	if ((self = [super init])) {
		_hasLiveEggs = NO;
		_playerNumber = playerNumber;
		
		for (int i = 0; i < SZLiveEggCount; ++i) {
			_liveEggs[i] = nil;
		}
	}
	
	return self;
}

- (id)init {
	return [self initWithPlayerNumber:0];
}

- (void)dealloc {
	[super dealloc];
}

- (void)addEgg:(SZEggBase*)egg x:(int)x y:(int)y {
	[_delegate grid:self didAddEgg:egg];
	[super addEgg:egg x:x y:y];
}

- (void)removeEggAtX:(int)x y:(int)y {
	SZEggBase *egg = [self eggAtX:x y:y];

	if ([_delegate respondsToSelector:@selector(grid:didRemoveEgg:)]) {
		[_delegate grid:self didRemoveEgg:egg];
	}
	
	[super removeEggAtX:x y:y];
}

- (void)createBottomRow {

	SZEggBase* egg = [[SZGridBottomLeftEgg alloc] init];
	[self addEgg:egg x:0 y:SZGridHeight - 1];
	[egg release];
	
	for (int i = 1; i < SZGridWidth - 1; ++i) {
		egg = [[SZGridBottomEgg alloc] init];
		[self addEgg:egg x:i y:SZGridHeight - 1];
		[egg release];
	}
	
	egg = [[SZGridBottomRightEgg alloc] init];
	[self addEgg:egg x:SZGridWidth - 1 y:SZGridHeight - 1];
	[egg release];
}

- (int)explodeEggs {
	
	int eggs = 0;

	NSMutableArray* chains = [self newPointChainsFromAllCoordinates];

	// These are the co-ordinates of the 4 eggs adjacent to the current egg
	static int xCoords[4] = { -1, 1, 0, 0 };
	static int yCoords[4] = { 0, 0, -1, 1 };

	for (NSArray* chain in chains) {
		eggs += [chain count];

		for (SZPoint* point in chain) {
			
			[[self eggAtX:point.x y:point.y] startExploding];

			// Remove any adjacent garbage
			for (int i = 0; i < 4; ++i) {

				SZEggBase* garbage = [self eggAtX:point.x + xCoords[i] y:point.y + yCoords[i]];
				if (garbage != nil && [garbage isKindOfClass:[SZGarbageEgg class]]) {
					if (garbage.state == SZEggStateNormal) {
						[garbage startExploding];
					}
				}
			}
		}
	}

	[chains release];

	return eggs;
}

- (NSMutableArray*)newPointChainsFromAllCoordinates {

	NSMutableArray* chains = [[NSMutableArray alloc] init];

	// Array of bools remembers which eggs we've already examined so that we
	// don't check them again and get stuck in a loop
	BOOL checkedData[SZGridSize];

	for (int i = 0; i < SZGridSize; ++i) {
		checkedData[i] = NO;
	}

	for (int y = 0; y < SZGridHeight; ++y) {
		for (int x = 0; x < SZGridWidth; ++x) {

			// Skip if egg already checked
			if (checkedData[x + (y * SZGridWidth)]) continue;

			NSMutableArray* chain = [self newPointChainFromCoordinatesX:x y:y checkedData:checkedData];

			// Only remember the chain if it has the minimum number of eggs in
			// it at least
			if ([chain count] >= SZChainLength) {
				[chains addObject:chain];
			}
			
			[chain release];
		}
	}
	
	return chains;
}

- (SZEggBase*)liveEgg:(int)index {
	NSAssert(index < 2, @"Only 2 live eggs are available.");
	
	return _liveEggs[index];
}

- (int)getPotentialExplodedEggCount:(int)x y:(int)y egg:(SZEggBase*)egg checkedData:(BOOL*)checkedData {

	NSAssert([self isValidCoordinateX:x y:y], @"Invalid co-ordinates supplied.");
	
	checkedData[x + (y * SZGridWidth)] = YES;

	// Set initial capacity to 11 as it is highly unlikely that longer chains
	// can be created
	NSMutableArray* chain = [[NSMutableArray alloc] initWithCapacity:11];
	NSMutableArray* singleChain = nil;

	// These are the co-ordinates of the 4 eggs adjacent to the current egg
	static int xCoords[4] = { -1, 1, 0, 0 };
	static int yCoords[4] = { 0, 0, -1, 1 };

	// Analyze all adjacent eggs
	for (int i = 0; i < 4; ++i) {

		SZEggBase* gridEgg = [self eggAtX:x + xCoords[i] y:y + yCoords[i]];
		if (gridEgg != nil && [gridEgg class] == [egg class]) {
			singleChain = [self newPointChainFromCoordinatesX:x + xCoords[i] y:y + yCoords[i] checkedData:checkedData];

			for (id point in singleChain) {
				[chain addObject:point];
			}

			[singleChain release];
		}
	}

	// Calculate how many garbage eggs will be exploded by the chain
	int garbageCount = 0;

	if ([chain count] >= SZChainLength) {
		SZEggBase* gridEgg = nil;

		for (id item in chain) {

			SZPoint* point = (SZPoint*)item;
			
			// Check all adjacent eggs to see if they are garbage
			for (int i = 0; i < 4; ++i) {

				gridEgg = [self eggAtX:point.x + xCoords[i] y:point.y + yCoords[i]];

				if ((gridEgg != nil) && (!checkedData[point.x + xCoords[i] + ((point.y + yCoords[i]) * SZGridWidth)])) {

					if ([gridEgg isKindOfClass:[SZGarbageEgg class]]) {
						checkedData[point.x + xCoords[i] + ((point.y + yCoords[i]) * SZGridWidth)] = YES;
						++garbageCount;
					}
				}
			}
		}
	}

	// Total length is the number of connected grid eggs found, plus the
	// egg we're trying to place, plus the number of garbage eggs that will
	// be exploded
	int length = (int)[chain count] + 1 + garbageCount;

	[chain release];

	return length;
}

- (NSMutableArray*)newPointChainFromCoordinatesX:(int)x y:(int)y checkedData:(BOOL*)checkedData {

	NSAssert([self isValidCoordinateX:x y:y], @"Invalid co-ordinates supplied.");

	// Stop if we've checked this egg already
	if (checkedData[x + (y * SZGridWidth)]) return nil;

	int index = 0;

	NSMutableArray* chain = [[NSMutableArray alloc] initWithCapacity:11];

	// Add the start of the chain to the list of eggs that comprise the chain
	SZPoint* startPoint = [[SZPoint alloc] initWithX:x y:y];

	[chain addObject:startPoint];
	[startPoint release];

	// Ensure we don't check this egg again
	checkedData[x + (y * SZGridWidth)] = YES;

	// Check the eggs that surround every egg in the chain to see if they
	// should be part of the chain.  If so, add them to the chain.
	while (index < [chain count]) {

		SZPoint* point = [chain objectAtIndex:index];
		SZEggBase* egg = [self eggAtX:point.x y:point.y];

		if (egg == nil) return chain;

		// Check if the egg on the left of this is part of the chain.  Ignore
		// the egg if it has already been checked.
		if (point.x - 1 >= 0 && !checkedData[point.x - 1 + (point.y * SZGridWidth)]) {

			if ([egg hasLeftConnection]) {

				// Egg is part of the chain so remember its co-ordinates
				SZPoint* adjacentPoint = [[SZPoint alloc] initWithX:point.x - 1 y:point.y];

				[chain addObject:adjacentPoint];

				// Now that we know this egg is part of a chain we don't want
				// to check it again
				checkedData[adjacentPoint.x + (adjacentPoint.y * SZGridWidth)] = YES;

				[adjacentPoint release];
			}
		}

		if (point.x + 1 < SZGridWidth && !checkedData[point.x + 1 + (point.y * SZGridWidth)]) {

			if ([egg hasRightConnection]) {

				SZPoint* adjacentPoint = [[SZPoint alloc] initWithX:point.x + 1 y:point.y];

				[chain addObject:adjacentPoint];

				checkedData[adjacentPoint.x + (adjacentPoint.y * SZGridWidth)] = YES;

				[adjacentPoint release];
			}
		}

		if (point.y - 1 >= 0 && !checkedData[point.x + ((point.y - 1) * SZGridWidth)]) {

			if ([egg hasTopConnection]) {

				SZPoint* adjacentPoint = [[SZPoint alloc] initWithX:point.x y:point.y - 1];

				[chain addObject:adjacentPoint];

				checkedData[adjacentPoint.x + (adjacentPoint.y * SZGridWidth)] = YES;

				[adjacentPoint release];
			}
		}

		if (point.y + 1 < SZGridHeight && !checkedData[point.x + ((point.y + 1) * SZGridWidth)]) {

			if ([egg hasBottomConnection]) {

				SZPoint* adjacentPoint = [[SZPoint alloc] initWithX:point.x y:point.y + 1];

				[chain addObject:adjacentPoint];

				checkedData[adjacentPoint.x + (adjacentPoint.y * SZGridWidth)] = YES;

				[adjacentPoint release];
			}
		}

		index++;
	}

	return chain;
}

- (void)dropLiveEggs {

	NSAssert(_hasLiveEggs, @"No live eggs in play.");

	BOOL hasLanded = NO;

	// Check both live eggs for collisions before we try to drop them.  This
	// prevents us from getting into a situation in which one of the pair drops
	// and the other hits something
	for (int i = 0; i < SZLiveEggCount; ++i) {

		// Check if the egg has landed on another.  We don't need to bother
		// checking if the egg is at the bottom of the grid because live
		// eggs can never reach there - the row of bottom eggs prevents it
		SZEggBase* eggBelow = [self eggAtX:_liveEggs[i].x y:_liveEggs[i].y + 1];

		if (eggBelow != nil) {

			// Do not land if the egg below is also falling
			if (eggBelow.state != SZEggStateFalling) {
				_hasLiveEggs = NO;

				[_liveEggs[i] startLanding];

				hasLanded = YES;
			}
		}
	}

	if (_hasLiveEggs) {

		// Eggs are still live - drop them to the next position.  Drop egg
		// 1 first as when vertical 1 is always below
		for (int i = SZLiveEggCount - 1; i >= 0; --i) {

			if (_liveEggs[i].hasDroppedHalfBlock) {
				[self moveEggFromSourceX:_liveEggs[i].x sourceY:_liveEggs[i].y toDestinationX:_liveEggs[i].x destinationY:_liveEggs[i].y + 1];
			}
			
			[_liveEggs[i] dropHalfBlock];
		}
	}

	if (hasLanded) {
		[_delegate didLandEggInGrid:self];
	}
}

- (BOOL)dropEggs {

	NSAssert(!_hasLiveEggs, @"Live eggs are in play.");

	BOOL hasDropped = NO;
	BOOL hasLanded = NO;
	BOOL isGarbage = NO;

	// Everything on the bottom row should have landed
	for (int x = 0; x < SZGridWidth; ++x) {
		SZEggBase* egg = [self eggAtX:x y:SZGridHeight - 1];

		if (egg != nil && egg.state == SZEggStateFalling) {

			[egg startLanding];
			hasLanded = YES;

			// Fire an event if the landed egg is garbage
			if ([egg isKindOfClass:[SZGarbageEgg class]]) {

				[_delegate grid:self didLandGarbageEgg:egg];

				isGarbage = YES;
			}
		}
	}

	// Drop starts at the second row from the bottom of the grid as there's no
	// point in dropping the bottom row
	for (int y = SZGridHeight - 2; y >= 0; --y) {
		for (int x = 0; x < SZGridWidth; ++x) {
			
			SZEggBase* egg = [self eggAtX:x y:y];

			// Ignore this egg if it's empty
			if (egg == nil) continue;

			// Drop the current egg if the egg below is empty
			if ([self eggAtX:x y:y + 1] == nil) {
				
				if (egg.hasDroppedHalfBlock) {
					[self moveEggFromSourceX:x sourceY:y toDestinationX:x destinationY:y + 1];
				}
				
				[egg dropHalfBlock];
				[egg startFalling];

				hasDropped = YES;
			} else if (egg.state == SZEggStateFalling) {

				if ([self eggAtX:x y:y + 1].state != SZEggStateFalling) {

					[egg startLanding];
					hasLanded = YES;

					// Fire an event if the landed egg is garbage
					if ([egg isKindOfClass:[SZGarbageEgg class]]) {

						[_delegate grid:self didLandGarbageEgg:egg];

						isGarbage = YES;
					}
				}
			}
		}
	}

	if (hasLanded) {
		if (isGarbage) {
			[_delegate didLandGarbageEggInGrid:self];
		} else {
			[_delegate didLandEggInGrid:self];
		}
	}

	return hasDropped;
}

- (BOOL)moveLiveEggsLeft {
	NSAssert(_hasLiveEggs, @"No live eggs in play");

	// 0 egg should always be on the left or at the top
	if (_liveEggs[0].x == 0) return NO;

	// Check the egg to the left
	if ([self eggAtX:_liveEggs[0].x - 1 y:_liveEggs[0].y] != nil) return NO;

	// If we've dropped half a step we also need to check the egg left and
	// down one
	if (_liveEggs[0].hasDroppedHalfBlock) {
		if ([self eggAtX:_liveEggs[0].x - 1 y:_liveEggs[0].y + 1] != nil) return NO;
	}

	// Check 1 egg if it is below the 0 egg
	if (_liveEggs[0].x == _liveEggs[1].x) {
		if ([self eggAtX:_liveEggs[1].x - 1 y:_liveEggs[1].y] != nil) return NO;

		// Check the egg left and down one if we've dropped a half step
		if (_liveEggs[1].hasDroppedHalfBlock) {
			if ([self eggAtX:_liveEggs[1].x - 1 y:_liveEggs[1].y + 1] != nil) return NO;
		}
	}

	// Eggs can move
	for (int i = 0; i < SZLiveEggCount; ++i) {
		[self moveEggFromSourceX:_liveEggs[i].x sourceY:_liveEggs[i].y toDestinationX:_liveEggs[i].x - 1 destinationY:_liveEggs[i].y];
	}

	return YES;
}

- (BOOL)moveLiveEggsRight {
	NSAssert(_hasLiveEggs, @"No live eggs in play");

	// 1 egg should always be on the right or at the bottom
	if (_liveEggs[1].x == SZGridWidth - 1) return NO;

	// Check the egg to the right
	if ([self eggAtX:_liveEggs[1].x + 1 y:_liveEggs[1].y] != nil) return NO;

	// If we've dropped half a step we also need to check the egg right and
	// down one
	if (_liveEggs[1].hasDroppedHalfBlock) {
		if ([self eggAtX:_liveEggs[1].x + 1 y:_liveEggs[1].y + 1] != nil) return NO;
	}

	// Check 0 egg if it is above the 1 egg
	if (_liveEggs[0].x == _liveEggs[1].x) {
		if ([self eggAtX:_liveEggs[0].x + 1 y:_liveEggs[0].y] != nil) return NO;

		// Check the egg right and down one if we've dropped a half egg
		if (_liveEggs[0].hasDroppedHalfBlock) {
			if ([self eggAtX:_liveEggs[0].x + 1 y:_liveEggs[0].y + 1] != nil) return NO;
		}
	}

	// Eggs can move
	for (int i = SZLiveEggCount - 1; i >= 0; --i) {
		[self moveEggFromSourceX:_liveEggs[i].x sourceY:_liveEggs[i].y toDestinationX:_liveEggs[i].x + 1 destinationY:_liveEggs[i].y];
	}

	return YES;
}

- (BOOL)rotateLiveEggsClockwise {
	NSAssert(_hasLiveEggs, @"No live eggs in play");

	// Determine whether to swap to a vertical or horizontal arrangement
	if (_liveEggs[0].y == _liveEggs[1].y) {

		// Swapping to vertical

		// Do not need to check for the bottom of the well as the bottom row of
		// eggs eliminates the possibility of eggs being there

		// Cannot swap if the egg below the egg on the right is populated
		if ([self eggAtX:_liveEggs[1].x y:_liveEggs[1].y + 1] != nil) return NO;

		// Cannot swap if the egg 2 below the egg on the right is populated
		// if we've dropped a half step
		if (_liveEggs[1].hasDroppedHalfBlock) {
			if ([self eggAtX:_liveEggs[1].x y:_liveEggs[1].y + 2] != nil) return NO;
		}

		// Perform the rotation

		// Move the right egg down one place
		[self moveEggFromSourceX:_liveEggs[1].x sourceY:_liveEggs[1].y toDestinationX:_liveEggs[1].x destinationY:_liveEggs[1].y + 1];

		// Move the left egg right one place
		[self moveEggFromSourceX:_liveEggs[0].x sourceY:_liveEggs[0].y toDestinationX:_liveEggs[0].x + 1 destinationY:_liveEggs[0].y];

	} else {

		// Swapping to horizontal

		// Cannot swap if the eggs are at the left edge of the well
		if (_liveEggs[0].x == 0) return NO;

		// Cannot swap if the egg to the left of the egg at the top is populated
		if ([self eggAtX:_liveEggs[0].x - 1 y:_liveEggs[0].y] != nil) return NO;

		// Cannot swap if the egg below the egg on the left of the top egg
		// is populated if we've dropped a half step
		if (_liveEggs[0].hasDroppedHalfBlock) {
			if ([self eggAtX:_liveEggs[0].x - 1 y:_liveEggs[0].y + 1] != nil) return NO;
		}

		// Perform the rotation

		// Move the bottom egg up and left
		[self moveEggFromSourceX:_liveEggs[1].x sourceY:_liveEggs[1].y toDestinationX:_liveEggs[0].x - 1 destinationY:_liveEggs[0].y];

		// 0 egg should always be on the left
		SZEggBase* tmp = _liveEggs[0];
		_liveEggs[0] = _liveEggs[1];
		_liveEggs[1] = tmp;
	}

	return YES;
}

- (BOOL)rotateLiveEggsAntiClockwise {
	NSAssert(_hasLiveEggs, @"No live eggs in play");

	// Determine whether the eggs swap to a vertical or horizontal arrangement
	if (_liveEggs[0].y == _liveEggs[1].y) {

		// Swapping to vertical

		// Do not need to check for the bottom of the well as the bottom row of
		// eggs eliminates the possibility of eggs being there

		// Cannot swap if the egg below the egg on the right is populated
		if ([self eggAtX:_liveEggs[1].x y:_liveEggs[1].y + 1] != nil) return NO;

		// Cannot swap if the egg 2 below the egg on the right is populated
		// if we've dropped a half step
		if (_liveEggs[1].hasDroppedHalfBlock) {
			if ([self eggAtX:_liveEggs[1].x y:_liveEggs[1].y + 2] != nil) return NO;
		}

		// Perform the rotation

		// Move the left egg down and right
		[self moveEggFromSourceX:_liveEggs[0].x sourceY:_liveEggs[0].y toDestinationX:_liveEggs[1].x destinationY:_liveEggs[1].y + 1];

		// 0 egg should always be at the top
		SZEggBase* tmp = _liveEggs[0];
		_liveEggs[0] = _liveEggs[1];
		_liveEggs[1] = tmp;

	} else {

		// Swapping to horizontal

		// Cannot swap if the eggs are at the left edge of the well
		if (_liveEggs[0].x == 0) return NO;

		// Cannot swap if the egg to the left of the egg at the top is populated
		if ([self eggAtX:_liveEggs[0].x - 1 y:_liveEggs[0].y] != nil) return NO;

		// Cannot swap if the egg below the egg on the left of the top egg
		// is populated if we've dropped a half step
		if (_liveEggs[0].hasDroppedHalfBlock) {
			if ([self eggAtX:_liveEggs[0].x - 1 y:_liveEggs[0].y + 1] != nil) return NO;
		}

		// Perform the rotation

		// Move the top egg left
		[self moveEggFromSourceX:_liveEggs[0].x sourceY:_liveEggs[0].y toDestinationX:_liveEggs[0].x - 1 destinationY:_liveEggs[0].y];

		// Move the bottom egg up
		[self moveEggFromSourceX:_liveEggs[1].x sourceY:_liveEggs[1].y toDestinationX:_liveEggs[1].x destinationY:_liveEggs[1].y - 1];
	}

	return YES;
}

- (BOOL)addLiveEggs:(SZEggBase*)egg1 egg2:(SZEggBase*)egg2 {

	// Do not add more live eggs if we have eggs already.  However, return
	// true because we don't want to treat this as a special case; as far as
	// any other code is concerned it did its job - live eggs are in play
	if (_hasLiveEggs) return YES;

	// Cannot add live eggs if the grid positions already contain eggs
	if ([self eggAtX:2 y:SZGridEntryY] != nil) return NO;
	if ([self eggAtX:3 y:SZGridEntryY] != nil) return NO;
	
	// Live eggs always appear at the same co-ordinates
	[self addEgg:egg1 x:2 y:SZGridEntryY];
	[self addEgg:egg2 x:3 y:SZGridEntryY];

	[egg1 startFalling];
	[egg2 startFalling];

	_liveEggs[0] = egg1;
	_liveEggs[1] = egg2;

	_hasLiveEggs = YES;

	return YES;
}

- (void)connectEggs {
	
	SZEggBase* egg = nil;
	
	for (int y = 0; y < SZGridHeight; ++y) {
		for (int x = 0; x < SZGridWidth; ++x) {
			egg = [self eggAtX:x y:y];
			
			if (egg == nil) continue;

			[egg connect:[self eggAtX:x y:y - 1]
				   right:[self eggAtX:x + 1 y:y]
				  bottom:[self eggAtX:x y:y + 1]
					left:[self eggAtX:x - 1 y:y]];
		}
	}
}

- (BOOL)iterate {

	BOOL result = NO;

	for (int y = 0; y < SZGridHeight; ++y) {
		for (int x = 0; x < SZGridWidth; ++x) {
			
			SZEggBase* egg = [self eggAtX:x y:y];
			
			if (egg == nil) continue;

			switch (egg.state) {
				case SZEggStateExploded:

					[self removeEggAtX:x y:y];
					result = YES;
					break;
				
				case SZEggStateExploding:
				case SZEggStateLanding:
				case SZEggStateRecoveringFromGarbageHit:

					// Hold up the grid until the egg has finished whatever it
					// is doing.
					result = YES;
					break;
					
				default:
					break;
			}
		}
	}

	return result;
}

- (void)addGarbage:(int)count {
	int columnHeights[SZGridWidth];
	int columns[SZGridWidth];
	int items = 0;

	for (int i = 0; i < SZGridWidth; ++i) {
		columnHeights[i] = -1;
	}

	// Add all column heights to the array in sorted order
	for (int i = 0; i < SZGridWidth; ++i) {
		int height = [self heightOfColumnAtIndex:i];
		int insertPoint = 0;

		// Locate where to insert this value
		for (int j = 0; j < items; ++j) {
			if (height <= columnHeights[j]) {
				insertPoint = j;
				break;
			}
			
			++insertPoint;
		}
				
		// Find the last column with the same height as the target.
		// Once this is known, we'll insert into a random column between
		// the two.  This ensures that the garbage insertion pattern
		// isn't predictable
		int targetEnd = insertPoint;
				
		while (targetEnd < items - 1 && columnHeights[targetEnd + 1] == height) {
			++targetEnd;
		}
				
		// Choose a column between the start and end at random
		insertPoint += rand() % (targetEnd - insertPoint + 1);
		
		// Shuffle items back one space to create a gap for the new value
		for (int k = items; k > insertPoint; --k) {
			columnHeights[k] = columnHeights[k - 1];
			columns[k] = columns[k - 1];
		}

		columnHeights[insertPoint] = height;
		columns[insertPoint] = i;
		++items;
	}

	// Add all garbage
	int activeColumns = 1;
	int y = columnHeights[0];

	if (count >= SZGridWidth) {
		[_delegate didAddGarbageEggRowToGrid:self];
	}

	while (count > 0) {

		int oldCount = count;

		while (activeColumns < SZGridWidth && columnHeights[activeColumns] <= y) ++activeColumns;

		for (int i = 0; i < activeColumns; ++i) {

			// Find a free egg
			int garbageY = 0;
			while ([self eggAtX:columns[i] y:garbageY] != nil && garbageY < SZGridHeight - SZGridEntryY) {
				++garbageY;
			}

			// If we couldn't find a free space we'll try it in the next column
			// instead
			if (garbageY == SZGridHeight - SZGridEntryY) continue;

			SZGarbageEgg* egg = [[SZGarbageEgg alloc] init];
			[self addEgg:egg x:columns[i] y:garbageY];
			[egg release];

			--count;

			if (count == 0) break;
		}

		// If we failed to place the egg the grid must be full
		if (oldCount == count) return;

		++y;
	}
}

- (id)copy {
	SZGrid* grid = [[SZGrid alloc] initWithPlayerNumber:_playerNumber];
	
	for (int y = 0; y < SZGridHeight; ++y) {
		for (int x = 0; x < SZGridWidth; ++x) {
			
			if ([self eggAtX:x y:y] == _liveEggs[0] || [self eggAtX:x y:y] == _liveEggs[1]) {
				continue;
			}
			
			Class eggClass = [[self eggAtX:x y:y] class];
			SZEggBase* egg = [[eggClass alloc] init];
			[grid addEgg:egg x:x y:y];
			[egg release];
		}
	}
	
	if (_hasLiveEggs) {
		SZEggBase* egg1 = [[[_liveEggs[0] class] alloc] init];
		SZEggBase* egg2 = [[[_liveEggs[1] class] alloc] init];
		
		[grid addLiveEggs:egg1 egg2:egg2];
		[egg1 release];
		[egg2 release];
	}
	
	return grid;
}

- (int)score {
	int score = 0;
	
	// Array of bools remembers which eggs we've already examined so that we
	// don't check them again and get stuck in a loop
	BOOL checkedData[SZGridSize];
	
	for (int i = 0; i < SZGridSize; ++i) {
		checkedData[i] = NO;
	}
	
	for (int y = 0; y < SZGridHeight; ++y) {
		for (int x = 0; x < SZGridWidth; ++x) {
			
			// Skip if egg already checked
			if (checkedData[x + (y * SZGridWidth)]) continue;
			
			if ([self eggAtX:x y:y] == nil) {
				
				// Empty eggs at the top are worth more than empty eggs at
				// the bottom of the grid, which makes the AI favour filling
				// eggs at the bottom of the grid.
				score += 6 * (SZGridHeight - y);
			} else {
			
				NSMutableArray* chain = [self newPointChainFromCoordinatesX:x y:y checkedData:checkedData];
				
				// Store the number of connections in the chain at the co-ords
				// of each member egg.  1 egg in the chain = 0 connections,
				// 2 eggs = 1 connection, etc.  The value is multiplied by
				// the y co-ord of the egg so that connections low in the grid
				// are worth more than connections high in the grid.  This makes
				// the AI try to make connections at the bottom of the grid,
				// which is more likely to trigger sequences of chains.
				
				if ([chain count] == 1) {

					// Penalise the score for single eggs left unattached
					score -= 8 * (SZGridHeight - y);
				} else {
					for (SZPoint* point in chain) {
						score += (1 << ([chain count])) * point.y;
					}
				}
				
				[chain release];
			}
		}
	}
	
	return score;
}

@end
