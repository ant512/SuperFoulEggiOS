#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "SZEggFactory.h"
#import "SZMessageBus.h"

typedef NS_ENUM(NSUInteger, SZNetworkSessionState) {
	SZNetworkSessionStateDisabled = 0,
	SZNetworkSessionStateWaitingForPeers = 1,
	SZNetworkSessionStateGatheredPeers = 2,
	SZNetworkSessionStateWaitingForGameStart = 3,
	SZNetworkSessionStateWaitingForRoundStart = 4,
	SZNetworkSessionStateActive = 5
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
- (void)sendBlockMove:(SZBlockMoveType)move;
- (void)sendStartGame;
- (void)sendStartRound;
- (void)sendPlaceNextEggs;
- (void)sendGarbage:(int)count fromPlayerNumber:(int)from toPlayerNumber:(int)to;
- (void)disable;

@end
