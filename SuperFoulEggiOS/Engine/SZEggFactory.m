#import "SZEggFactory.h"
#import "SZRedEgg.h"
#import "SZBlueEgg.h"
#import "SZGreenEgg.h"
#import "SZYellowEgg.h"
#import "SZOrangeEgg.h"
#import "SZPurpleEgg.h"

@implementation SZEggFactory

- (id)initWithPlayerCount:(int)playerCount eggColourCount:(int)eggColourCount {
	if ((self = [super init])) {
		_playerCount = playerCount;
		_eggColourCount = eggColourCount;
		
		_eggList = [[NSMutableArray alloc] init];
		_playerEggListIndices = malloc(sizeof(int) * playerCount);
		
		[self clear];
	}
	
	return self;
}

- (void)dealloc {
	free(_playerEggListIndices);
	
	[_eggList release];
	[super dealloc];
}

- (void)clear {
	for (int i = 0; i < _playerCount; ++i) {
		_playerEggListIndices[i] = 0;
	}
	
	[_eggList removeAllObjects];
}

- (void)addRandomEggClass {
	[_eggList addObject:[self randomEggClass]];
}

- (void)expireUsedEggClasses {
	int minimumIndex = INT_MAX;
	
	// Locate the earliest-used egg in the list
	for (int i = 0; i < _playerCount; ++i) {
		if (_playerEggListIndices[i] < minimumIndex) minimumIndex = _playerEggListIndices[i];
	}
	
	// Reduce the indices of all players as we are going to trash everything
	// before the earliest-used egg
	for (int i = 0; i < _playerCount; ++i) {
		_playerEggListIndices[i] -= minimumIndex;
	}
	
	// Trash the unused eggs from the start of the array
	while (minimumIndex > 0) {
		[_eggList removeObjectAtIndex:0];
		--minimumIndex;
	}
}

- (Class)randomEggClass {
	int type = rand() % _eggColourCount;

	switch (type) {
		case 0:
			return [SZRedEgg class];
		case 1:
			return [SZBlueEgg class];
		case 2:
			return [SZYellowEgg class];
		case 3:
			return [SZPurpleEgg class];
		case 4:
			return [SZGreenEgg class];
		case 5:
			return [SZOrangeEgg class];
	}
	
	// Included to silence compiler warning
	return [SZRedEgg class];
}

- (SZEggBase*)newEggForPlayerNumber:(int)playerNumber {
	int index = _playerEggListIndices[playerNumber]++;

	// If the player is requesting a egg past the end of the egg list,
	// we need to append a new pair before we can return it
	if (index == [_eggList count]) {
		[self addRandomEggClass];
	}

	// Initialise a new egg instance from the class at the current egglist
	// index that this player is using
	SZEggBase* egg = [[[_eggList objectAtIndex:index] alloc] init];
	
	// We can try to expire any old egg in the list now
	[self expireUsedEggClasses];

	return egg;
}

@end
