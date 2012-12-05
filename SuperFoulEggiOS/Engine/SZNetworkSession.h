#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@interface SZNetworkSession : NSObject <GKSessionDelegate> {
	GKSession *_session;
}

@property (readonly) BOOL isServer;
@property (readonly) BOOL isRunning;

+ (SZNetworkSession *)sharedSession;

- (void)start;
- (void)sendLiveBlockMoveLeft;
- (void)sendLiveBlockMoveRight;
- (void)sendLiveBlockDrop;
- (void)sendLiveBlockRotateClockwise;
- (void)sendLiveBlockRotateAnticlockwise;
- (void)sendNewEgg:(char)eggColour;

@end
