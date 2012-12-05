#import "SZEggFactory.h"
#import "SZRedEgg.h"
#import "SZBlueEgg.h"
#import "SZGreenEgg.h"
#import "SZYellowEgg.h"
#import "SZOrangeEgg.h"
#import "SZPurpleEgg.h"
#import "SZNetworkSession.h"

@implementation SZEggFactory

+ (SZEggFactory *)sharedFactory {
	static SZEggFactory *sharedFactory = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		sharedFactory = [[SZEggFactory alloc] init];
	});

	return sharedFactory;
}

- (void)setPlayerCount:(int)playerCount andEggColourCount:(int)eggColourCount {
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

- (void)addEggClassFromInt:(int)value {
	[_eggList addObject:[self eggClassFromInt:value]];
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

- (Class)eggClassFromInt:(int)value {
	switch (value) {
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

- (Class)randomEggClass {
	int type = rand() % _eggColourCount;

	// This could be problematic.  We've got two (or potentially, many) peers
	// connected together.  Neither one is a server.  When one peer runs out of
	// eggs in its factory it creates a new egg and sends the colour to its
	// peers.  What happens if both peers need a new egg at exactly the same
	// time?  They'll both create new eggs and send the transmissions to each
	// other.  They'll become out of sync.  This is especially problematic at
	// startup, as we want both games to start simultaneously.
	//
	// Potential fix: one of the peers is designated to be the server.  When a
	// grid runner needs a new egg it switches to a new "waiting for new eggs"
	// state.  It the peer is the server it just creates a new local egg.  If
	// not, it sends a request to the server and asks for a new egg.  When the
	// response comes back, the egg is added to the factory and the grid runner
	// switches back to its "live blocks" state.
	//
	// We probably want to switch from peers to client/server.

	[[SZNetworkSession sharedSession] sendNewEgg:type];

	return [self eggClassFromInt:type];
}

- (BOOL)hasEggsForPlayer:(int)playerNumber count:(int)count {
	int index = _playerEggListIndices[playerNumber] + count;

	return (index < _eggList.count);
}

- (SZEggBase *)newEggForPlayerNumber:(int)playerNumber {
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
