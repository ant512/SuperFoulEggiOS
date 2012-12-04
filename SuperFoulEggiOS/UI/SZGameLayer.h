#import "cocos2d.h"

#import "SZGrid.h"
#import "SZGridRunner.h"
#import "SZSmartAIController.h"
#import "SZGameController.h"
#import "SZPlayerOneController.h"
#import "SZPlayerTwoController.h"
#import "SZGrid.h"
#import "SZGridRunner.h"
#import "SZGameLayer.h"
#import "SZEggSpriteConnector.h"
#import "SZUIConstants.h"

typedef NS_ENUM(NSUInteger, SZGameState) {
	SZGameStateActive = 0,
	SZGameStatePaused = 1,
	SZGameStateGameOverEffect = 2,
	SZGameStateGameOver = 3
};

@interface SZGameLayer : CCLayer <SZGridDelegate, SZGridRunnerDelegate> {
	CCSpriteBatchNode* _redEggSpriteSheet;
	CCSpriteBatchNode* _blueEggSpriteSheet;
	CCSpriteBatchNode* _greenEggSpriteSheet;
	CCSpriteBatchNode* _yellowEggSpriteSheet;
	CCSpriteBatchNode* _orangeEggSpriteSheet;
	CCSpriteBatchNode* _purpleEggSpriteSheet;
	CCSpriteBatchNode* _garbageEggSpriteSheet;
	CCSpriteBatchNode* _gridBottomEggSpriteSheet;
	CCSpriteBatchNode* _gridBottomLeftEggSpriteSheet;
	CCSpriteBatchNode* _gridBottomRightEggSpriteSheet;
	CCSpriteBatchNode* _incomingSpriteSheet;
	CCSpriteBatchNode* _messageSpriteSheet;
	CCSpriteBatchNode* _playerTagSpriteSheet;
	CCSpriteBatchNode* _orangeNumberSpriteSheet;
	CCSpriteBatchNode* _purpleNumberSpriteSheet;

	SZGameState _state;
	
	SZGridRunner* _runners[SZMaximumPlayers];
	NSMutableArray* _eggSpriteConnectors[SZMaximumPlayers];
	NSMutableArray* _incomingGarbageSprites[SZMaximumPlayers];
	int _gameWins[SZMaximumPlayers];
	int _matchWins[SZMaximumPlayers];
	
	int _deathEffectTimer;
	
	int _columnTarget;
	int _dragStartColumn;
	int _dragStartX;
	int _didDrag;
}

+ (CCScene*)scene;

@end
