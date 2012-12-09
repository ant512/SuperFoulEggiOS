#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "SZEggFactory.h"

typedef NS_ENUM(NSUInteger, SZNetworkSessionState) {
	SZNetworkSessionStateWaitingForPeers = 0,
	SZNetworkSessionStateGatheredPeers = 1,
	SZNetworkSessionStateWaitingForGameStart = 2,
	SZNetworkSessionStateWaitingForRoundStart = 3,
	SZNetworkSessionStateActive = 4,
	SZNetworkSessionStateWaitingForEggVotes = 5,
};

@interface SZNetworkSession : NSObject <GKSessionDelegate> {
	GKSession *_session;
	NSUInteger _eggVoteNumber;
	NSUInteger _voteCount;
	SZEggColour _eggVoteColour1;
	SZEggColour _eggVoteColour2;
	NSUInteger _playerCount;
	SZNetworkSessionState _state;
	NSString *_highestPeerId;
}

+ (SZNetworkSession *)sharedSession;

- (void)startWithPlayerCount:(NSUInteger)playerCount;
- (void)resetEggVotes;
- (void)sendLiveBlockMoveLeft;
- (void)sendLiveBlockMoveRight;
- (void)sendLiveBlockDrop;
- (void)sendLiveBlockRotateClockwise;
- (void)sendLiveBlockRotateAnticlockwise;
- (void)sendEggPairVote;
- (void)sendStartGame;
- (void)sendStartRound;

@end
