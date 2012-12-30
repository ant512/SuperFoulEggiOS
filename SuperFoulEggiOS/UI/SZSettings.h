#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SZAIType) {
	SZAITypeInsane = 0,
	SZAITypeHard = 2,
	SZAITypeMedium = 3,
	SZAITypeEasy = 6
};

typedef NS_ENUM(NSUInteger, SZGameType) {
	SZGameTypePractice = 0,
	SZGameTypeSinglePlayer = 1,
	SZGameTypeTwoPlayer = 2,
};

@interface SZSettings : NSObject

@property(readwrite) SZAIType aiType;
@property(readwrite) SZGameType gameType;
@property(readwrite) int height;
@property(readwrite) int speed;
@property(readwrite) int gamesPerMatch;
@property(readwrite) int eggColours;
@property(readwrite) int randomEggSeed;

@property(readwrite) unichar keyCodeOneLeft;
@property(readwrite) unichar keyCodeOneRight;
@property(readwrite) unichar keyCodeOneUp;
@property(readwrite) unichar keyCodeOneDown;
@property(readwrite) unichar keyCodeOneA;
@property(readwrite) unichar keyCodeOneB;
@property(readwrite) unichar keyCodeOneStart;

@property(readwrite) unichar keyCodeTwoLeft;
@property(readwrite) unichar keyCodeTwoRight;
@property(readwrite) unichar keyCodeTwoUp;
@property(readwrite) unichar keyCodeTwoDown;
@property(readwrite) unichar keyCodeTwoA;
@property(readwrite) unichar keyCodeTwoB;
@property(readwrite) unichar keyCodeTwoStart;

@property(readwrite) unichar keyCodeQuit;

+ (SZSettings *)sharedSettings;
- (id)init;
- (void)save;

@end
