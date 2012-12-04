#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@interface SZNetworkSession : NSObject <GKSessionDelegate> {
	GKSession *_session;
}

+ (SZNetworkSession *)sharedSession;

- (void)start;
- (void)sendLiveBlockMoveLeft;
- (void)sendLiveBlockMoveRight;
- (void)sendLiveBlockDrop;
- (void)sendLiveBlockRotateClockwise;
- (void)sendLiveBlockRotateAnticlockwise;

@end
