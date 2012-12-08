#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "SZEggFactory.h"

typedef NS_ENUM(NSUInteger, SZNetworkSessionState) {
	SZNetworkSessionStateWaitingForPeers = 0,
	SZNetworkSessionStateGatheredPeers = 1,
	SZNetworkSessionStateWaitingForStart = 2,
	SZNetworkSessionStateActive = 3,
	SZNetworkSessionStateWaitingForEggVotes = 4
};

@interface SZNetworkSession : NSObject <GKSessionDelegate> {
	GKSession *_session;
	NSUInteger _eggVoteNumber;
	NSUInteger _eggVoteCount;
	SZEggColour _eggVoteColour1;
	SZEggColour _eggVoteColour2;
	NSUInteger _playerCount;
	SZNetworkSessionState _state;
	NSString *_highestPeerId;
	NSUInteger _startGameVoteCount;
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

@end
