#import "cocos2d.h"

#import "SZGrid.h"
#import "GridRunner.h"
#import "SmartAIController.h"
#import "ControllerProtocol.h"
#import "BlockFactory.h"
#import "SZPlayerOneController.h"
#import "SZPlayerTwoController.h"
#import "SZGrid.h"
#import "GridRunner.h"
#import "ControllerProtocol.h"
#import "BlockFactory.h"
#import "GameLayer.h"
#import "SZEggSpriteConnector.h"

#define MAX_PLAYERS 2
#define FRAME_RATE 60
#define GRID_1_X 80
#define GRID_2_X 656
#define GRID_Y 0
#define NEXT_BLOCK_1_X 440
#define NEXT_BLOCK_2_X 578
#define NEXT_BLOCK_Y -280
#define GRID_2_TAG_X 569
#define GRID_2_TAG_Y 462
#define GRID_1_MATCH_SCORE_X 476
#define GRID_1_GAME_SCORE_X 563
#define GRID_1_SCORES_Y 363
#define GRID_2_MATCH_SCORE_X 509
#define GRID_2_GAME_SCORE_X 602
#define GRID_2_SCORES_Y 285

typedef NS_ENUM(NSUInteger, SZGameState) {
	SZGameStateActive = 0,
	SZGameStatePaused = 1,
	SZGameStateGameOverEffect = 2,
	SZGameStateGameOver = 3
};

@interface GameLayer : CCLayer <SZGridDelegate, SZGridRunnerDelegate> {
	CCSpriteBatchNode* _redBlockSpriteSheet;
	CCSpriteBatchNode* _blueBlockSpriteSheet;
	CCSpriteBatchNode* _greenBlockSpriteSheet;
	CCSpriteBatchNode* _yellowBlockSpriteSheet;
	CCSpriteBatchNode* _orangeBlockSpriteSheet;
	CCSpriteBatchNode* _purpleBlockSpriteSheet;
	CCSpriteBatchNode* _garbageBlockSpriteSheet;
	CCSpriteBatchNode* _gridBottomBlockSpriteSheet;
	CCSpriteBatchNode* _gridBottomLeftBlockSpriteSheet;
	CCSpriteBatchNode* _gridBottomRightBlockSpriteSheet;
	CCSpriteBatchNode* _incomingSpriteSheet;
	CCSpriteBatchNode* _messageSpriteSheet;
	CCSpriteBatchNode* _playerTagSpriteSheet;
	CCSpriteBatchNode* _orangeNumberSpriteSheet;
	CCSpriteBatchNode* _purpleNumberSpriteSheet;
	
	BlockFactory* _blockFactory;
	SZGameState _state;
	
	GridRunner* _runners[MAX_PLAYERS];
	NSMutableArray* _blockSpriteConnectors[MAX_PLAYERS];
	NSMutableArray* _incomingGarbageSprites[MAX_PLAYERS];
	int _gameWins[MAX_PLAYERS];
	int _matchWins[MAX_PLAYERS];
	
	int _deathEffectTimer;
	
	int _columnTarget;
	int _dragStartColumn;
	int _dragStartX;
	int _didDrag;
}

+ (CCScene*)scene;

@end
