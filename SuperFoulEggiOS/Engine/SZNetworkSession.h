#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "SZEggFactory.h"
#import "SZMessageBus.h"

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
}

@property (readonly) SZNetworkSessionState state;

+ (SZNetworkSession *)sharedSession;

- (void)startWithPlayerCount:(NSUInteger)playerCount;
- (void)sendBlockMove:(SZBlockMoveType)move fromPlayerNumber:(int)from;
- (void)sendStartGame;
- (void)sendStartRound;
- (void)sendPlaceNextEggsFromPlayerNumber:(int)playerNumber;

@end
