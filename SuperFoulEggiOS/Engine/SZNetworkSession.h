#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "SZEggFactory.h"

@interface SZNetworkSession : NSObject <GKSessionDelegate> {
	GKSession *_session;
	NSUInteger _eggVoteNumber;
	NSMutableDictionary *_currentVotes;
	NSUInteger _playerCount;
	BOOL _isWaitingForVotes;
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
