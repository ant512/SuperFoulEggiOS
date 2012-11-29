#import "Settings.h"

@implementation Settings

+ (Settings*)sharedSettings {
	static Settings *sharedSettings = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		sharedSettings = [[Settings alloc] init];
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
		
		_eggColours = [[NSUserDefaults standardUserDefaults] objectForKey:@"BlockColours"] ? [[[NSUserDefaults standardUserDefaults] objectForKey:@"BlockColours"] intValue] : 4;
		
		_keyCodeOneLeft = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneLeft"] ? [[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneLeft"] intValue] : DEFAULT_KEY_CODE_ONE_LEFT;
		
		_keyCodeOneRight = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneRight"] ?[[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneRight"] intValue] : DEFAULT_KEY_CODE_ONE_RIGHT;
		
		_keyCodeOneUp = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneUp"] ?[[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneUp"] intValue] : DEFAULT_KEY_CODE_ONE_UP;
		
		_keyCodeOneDown = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneDown"] ?[[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneDown"] intValue] : DEFAULT_KEY_CODE_ONE_DOWN;
		
		_keyCodeOneA = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneA"] ?[[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneA"] intValue] : DEFAULT_KEY_CODE_ONE_A;
		
		_keyCodeOneB = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneB"] ?[[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeOneB"] intValue] : DEFAULT_KEY_CODE_ONE_B;
		
		_keyCodeOneStart = DEFAULT_KEY_CODE_ONE_START;
		
		_keyCodeTwoLeft = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoLeft"] ? [[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoLeft"] intValue] : DEFAULT_KEY_CODE_TWO_LEFT;
		
		_keyCodeTwoRight = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoRight"] ?[[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoRight"] intValue] : DEFAULT_KEY_CODE_TWO_RIGHT;
		
		_keyCodeTwoUp = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoUp"] ?[[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoUp"] intValue] : DEFAULT_KEY_CODE_TWO_UP;
		
		_keyCodeTwoDown = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoDown"] ?[[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoDown"] intValue] : DEFAULT_KEY_CODE_TWO_DOWN;
		
		_keyCodeTwoA = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoA"] ?[[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoA"] intValue] :DEFAULT_KEY_CODE_TWO_A;
		
		_keyCodeTwoB = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoB"] ?[[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyCodeTwoB"] intValue] :DEFAULT_KEY_CODE_TWO_B;
		
		_keyCodeTwoStart = DEFAULT_KEY_CODE_TWO_START;
		
		_keyCodeQuit = DEFAULT_KEY_CODE_QUIT;
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
