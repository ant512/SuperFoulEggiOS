#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "SZEggFactory.h"

typedef NS_ENUM(NSUInteger, SZNetworkSessionState) {
	SZNetworkSessionStateWaitingForPeers = 0,
	SZNetworkSessionStateGatheredPeers = 1,
	SZNetworkSessionStateWaitingForGameStart = 2,
	SZNetworkSessionStateWaitingForRoundStart = 3,
	SZNetworkSessionStateActive = 4,
	SZNetworkSessionStateReadyForNextEgg = 5
};

@interface SZNetworkSession : NSObject <GKSessionDelegate> {
	GKSession *_session;
	NSUInteger _voteCount;
	NSUInteger _playerCount;
	SZNetworkSessionState _state;
	NSString *_highestPeerId;
	int _randomEggSeed;
	NSMutableDictionary *_nextEggAcknowledgements;
}

@property (readonly) SZNetworkSessionState state;

+ (SZNetworkSession *)sharedSession;

- (void)startWithPlayerCount:(NSUInteger)playerCount;
- (void)sendLiveBlockMoveLeft;
- (void)sendLiveBlockMoveRight;
- (void)sendLiveBlockMoveDown;
- (void)sendLiveBlockDrop;
- (void)sendLiveBlockRotateClockwise;
- (void)sendLiveBlockRotateAnticlockwise;
- (void)sendStartGame;
- (void)sendStartRound;
- (void)sendReadyForNextEgg:(char)playerNumber;

@end
