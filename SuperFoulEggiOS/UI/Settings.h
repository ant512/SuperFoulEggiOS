#import <Foundation/Foundation.h>

#define DEFAULT_KEY_CODE_ONE_LEFT 0x64
#define DEFAULT_KEY_CODE_ONE_RIGHT 0x67
#define DEFAULT_KEY_CODE_ONE_UP 0x72
#define DEFAULT_KEY_CODE_ONE_DOWN 0x66
#define DEFAULT_KEY_CODE_ONE_A 0x73
#define DEFAULT_KEY_CODE_ONE_B 0x61
#define DEFAULT_KEY_CODE_ONE_START 0x20

#define DEFAULT_KEY_CODE_TWO_LEFT 0xF702
#define DEFAULT_KEY_CODE_TWO_RIGHT 0xF703
#define DEFAULT_KEY_CODE_TWO_UP 0xF700
#define DEFAULT_KEY_CODE_TWO_DOWN 0xF701
#define DEFAULT_KEY_CODE_TWO_A 0x2E
#define DEFAULT_KEY_CODE_TWO_B 0x2C
#define DEFAULT_KEY_CODE_TWO_START 0x0D

#define DEFAULT_KEY_CODE_QUIT 0x1B

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

@interface Settings : NSObject

@property(readwrite) SZAIType aiType;
@property(readwrite) SZGameType gameType;
@property(readwrite) int height;
@property(readwrite) int speed;
@property(readwrite) int gamesPerMatch;
@property(readwrite) int eggColours;

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

+ (Settings*)sharedSettings;
- (id)init;
- (void)save;

@end
