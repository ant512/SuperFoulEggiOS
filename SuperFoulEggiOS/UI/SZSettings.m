#import "SZSettings.h"

typedef NS_ENUM(NSUInteger, SZDefaultKeyCodeOne) {
	SZDefaultKeyCodeOneLeft = 0x64,
	SZDefaultKeyCodeOneRight = 0x67,
	SZDefaultKeyCodeOneUp = 0x72,
	SZDefaultKeyCodeOneDown = 0x66,
	SZDefaultKeyCodeOneA = 0x73,
	SZDefaultKeyCodeOneB = 0x61,
	SZDefaultKeyCodeOneStart = 0x20
};

typedef NS_ENUM(NSUInteger, SZDefaultKeyCodeTwo) {
	SZDefaultKeyCodeTwoLeft = 0xF702,
	SZDefaultKeyCodeTwoRight = 0xF703,
	SZDefaultKeyCodeTwoUp = 0xF700,
	SZDefaultKeyCodeTwoDown = 0xF701,
	SZDefaultKeyCodeTwoA = 0x2E,
	SZDefaultKeyCodeTwoB = 0x2C,
	SZDefaultKeyCodeTwoStart = 0x0D
};

const int SZDefaultKeyCodeQuit = 0x1B;

@implementation SZSettings

+ (SZSettings *)sharedSettings {
	static SZSettings *sharedSettings = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		sharedSettings = [[SZSettings alloc] init];
	});
	
	return sharedSettings;
}

- (id)init {
	if ((self = [super init])) {
		
		_aiType = [[NSUserDefaults standardUserDefaults] objectForKey:@"AIType"] ? [[[NSUserDefaults standardUserDefaults] objectForKey:@"AIType"] intValue] : SZAITypeHard;
		
		_gameType = [[NSUserDefaults standardUserDefaults] objectForKey:@"GameType"] ? [[[NSUserDefaults standardUserDefaults] objectForKey:@"GameType"] intValue] : SZGameTypeSinglePlayer;
		
		_height = [[NSUserDefaults standardUserDefaults] objectForKey:@"Height"] ? [[[NSUserDefaults standardUserDefaults] objectForKey:@"Height"] intValue] : 0;
		
		_speed = [[NSUserDefaults standardUserDefaults] objectForKey:@"Speed"] ? [[[NSUserDefaults standardUserDefaults] objectForKey:@"Speed"] intValue] : 0;
		
		_gamesPerMatch = [[NSUserDefaults standardUserDefaults] objectForKey:@"GamesPerMatch"] ? [[[NSUserDefaults standardUserDefaults] objectForKey:@"GamesPerMatch"] intValue] : 3;
		
		_eggColours = [[NSUserDefaults standardUserDefaults] objectForKey:@"EggColours"] ? [[[NSUserDefaults standardUserDefaults] objectForKey:@"EggColours"] intValue] : 4;
		
		_keyCodeOneLeft = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneLeft"] ? [[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneLeft"] intValue] : SZDefaultKeyCodeOneLeft;
		
		_keyCodeOneRight = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneRight"] ?[[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneRight"] intValue] : SZDefaultKeyCodeOneRight;
		
		_keyCodeOneUp = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneUp"] ?[[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneUp"] intValue] : SZDefaultKeyCodeOneUp;
		
		_keyCodeOneDown = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneDown"] ?[[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneDown"] intValue] : SZDefaultKeyCodeOneDown;
		
		_keyCodeOneA = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneA"] ?[[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneA"] intValue] : SZDefaultKeyCodeOneA;
		
		_keyCodeOneB = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneB"] ?[[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneB"] intValue] : SZDefaultKeyCodeOneB;
		
		_keyCodeOneStart = SZDefaultKeyCodeOneStart;
		
		_keyCodeTwoLeft = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoLeft"] ? [[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoLeft"] intValue] : SZDefaultKeyCodeTwoLeft;
		
		_keyCodeTwoRight = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoRight"] ?[[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoRight"] intValue] : SZDefaultKeyCodeTwoRight;
		
		_keyCodeTwoUp = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoUp"] ?[[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoUp"] intValue] : SZDefaultKeyCodeTwoUp;
		
		_keyCodeTwoDown = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoDown"] ?[[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoDown"] intValue] : SZDefaultKeyCodeTwoDown;
		
		_keyCodeTwoA = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoA"] ?[[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoA"] intValue] :SZDefaultKeyCodeTwoA;
		
		_keyCodeTwoB = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoB"] ?[[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoB"] intValue] :SZDefaultKeyCodeTwoB;
		
		_keyCodeTwoStart = SZDefaultKeyCodeTwoStart;
		
		_keyCodeQuit = SZDefaultKeyCodeQuit;

		_randomEggSeed = rand();
	}
	return self;
}

- (void)save {
	[[NSUserDefaults standardUserDefaults] setObject:@(_keyCodeOneLeft) forKey:@"KeyCodeOneLeft"];
	[[NSUserDefaults standardUserDefaults] setObject:@(_keyCodeOneRight) forKey:@"KeyCodeOneRight"];
	[[NSUserDefaults standardUserDefaults] setObject:@(_keyCodeOneUp) forKey:@"KeyCodeOneUp"];
	[[NSUserDefaults standardUserDefaults] setObject:@(_keyCodeOneDown) forKey:@"KeyCodeOneDown"];
	[[NSUserDefaults standardUserDefaults] setObject:@(_keyCodeOneA) forKey:@"KeyCodeOneA"];
	[[NSUserDefaults standardUserDefaults] setObject:@(_keyCodeOneB) forKey:@"KeyCodeOneB"];

	[[NSUserDefaults standardUserDefaults] setObject:@(_keyCodeTwoLeft) forKey:@"KeyCodeTwoLeft"];
	[[NSUserDefaults standardUserDefaults] setObject:@(_keyCodeTwoRight) forKey:@"KeyCodeTwoRight"];
	[[NSUserDefaults standardUserDefaults] setObject:@(_keyCodeTwoUp) forKey:@"KeyCodeTwoUp"];
	[[NSUserDefaults standardUserDefaults] setObject:@(_keyCodeTwoDown) forKey:@"KeyCodeTwoDown"];
	[[NSUserDefaults standardUserDefaults] setObject:@(_keyCodeTwoA) forKey:@"KeyCodeTwoA"];
	[[NSUserDefaults standardUserDefaults] setObject:@(_keyCodeTwoB) forKey:@"KeyCodeTwoB"];
	
	[[NSUserDefaults standardUserDefaults] setObject:@(_aiType) forKey:@"AIType"];
	[[NSUserDefaults standardUserDefaults] setObject:@(_gameType) forKey:@"GameType"];
	[[NSUserDefaults standardUserDefaults] setObject:@(_height) forKey:@"Height"];
	[[NSUserDefaults standardUserDefaults] setObject:@(_speed) forKey:@"Speed"];
	[[NSUserDefaults standardUserDefaults] setObject:@(_gamesPerMatch) forKey:@"GamesPerMatch"];
	[[NSUserDefaults standardUserDefaults] setObject:@(_eggColours) forKey:@"EggColours"];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
}

@end
