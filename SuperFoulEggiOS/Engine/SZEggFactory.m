#import "SZEggFactory.h"
#import "SZRedEgg.h"
#import "SZBlueEgg.h"
#import "SZGreenEgg.h"
#import "SZYellowEgg.h"
#import "SZOrangeEgg.h"
#import "SZPurpleEgg.h"
#import "SZGarbageEgg.h"
#import "MTRandom.h"

@implementation SZEggFactory

+ (SZEggFactory *)sharedFactory {
	static SZEggFactory *sharedFactory = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		sharedFactory = [[SZEggFactory alloc] init];
	});

	return sharedFactory;
}

- (id)init {
	if ((self = [super init])) {
	}

	return self;
}

- (void)addEggPairColour1:(SZEggColour)colour1 colour2:(SZEggColour)colour2; {

	NSLog(@"Received egg colour");

	[self addEggClassFromColour:colour1];
	[self addEggClassFromColour:colour2];
}

- (void)setPlayerCount:(int)playerCount
		eggColourCount:(int)eggColourCount {

	_playerCount = playerCount;
	_eggColourCount = eggColourCount;

	if (_playerEggListIndices) {		
		free(_playerEggListIndices);
	}

	_playerEggListIndices = malloc(sizeof(int) * playerCount);

	[_eggList release];

	_eggList = [[NSMutableArray alloc] init];

	[self clear];
}

- (void)setRandomSeed:(int)seed {
	[_random release];
	_random = [[MTRandom alloc] initWithSeed:seed];
}

- (void)dealloc {
	free(_playerEggListIndices);
	
	[_eggList release];
	[_random release];
	
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

- (void)addEggClassFromColour:(SZEggColour)value {
	[_eggList addObject:[self eggClassFromColour:value]];
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

- (Class)eggClassFromColour:(SZEggColour)value {
	switch (value) {
		case SZEggColourRed:
			return [SZRedEgg class];
		case SZEggColourBlue:
			return [SZBlueEgg class];
		case SZEggColourYellow:
			return [SZYellowEgg class];
		case SZEggColourPurple:
			return [SZPurpleEgg class];
		case SZEggColourGreen:
			return [SZGreenEgg class];
		case SZEggColourOrange:
			return [SZOrangeEgg class];
		case SZEggColourGarbage:
			return [SZGarbageEgg class];
		case SZEggColourNone:
			return nil;
	}

	// Included to silence compiler warning
	return [SZRedEgg class];
}

- (Class)randomEggClass {
	int colour = SZEggColourRed + ([_random randomUInt32From:0 to:_eggColourCount - 1]);
	return [self eggClassFromColour:colour];
}

- (SZEggColour)colourOfEgg:(SZEggBase *)egg {
	if ([egg class] == [SZRedEgg class]) {
		return SZEggColourRed;
	} else if ([egg class] == [SZOrangeEgg class]) {
		return SZEggColourOrange;
	} else if ([egg class] == [SZBlueEgg class]) {
		return SZEggColourBlue;
	} else if ([egg class] == [SZGreenEgg class]) {
		return SZEggColourGreen;
	} else if ([egg class] == [SZYellowEgg class]) {
		return SZEggColourYellow;
	} else if ([egg class] == [SZPurpleEgg class]) {
		return SZEggColourPurple;
	} else if ([egg class] == [SZRedEgg class]) {
		return SZEggColourGarbage;
	}

	return SZEggColourNone;
}

- (SZEggBase *)newEggForPlayerNumber:(int)playerNumber {
	int index = _playerEggListIndices[playerNumber]++;
	
	if (index >= _eggList.count) {
		[self addRandomEggClass];
		[self addRandomEggClass];
	}
	
	// Initialise a new egg instance from the class at the current egglist
	// index that this player is using
	SZEggBase *egg = [[[_eggList objectAtIndex:index] alloc] init];
	
	// We can try to expire any old egg in the list now
	[self expireUsedEggClasses];

	return egg;
}

@end
