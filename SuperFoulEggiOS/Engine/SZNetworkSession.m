#import "SZNetworkSession.h"
#import "SZEngineConstants.h"
#import "SZEggFactory.h"
#import "SZEggBase.h"

typedef NS_ENUM(char, SZMessageType) {
	SZMessageTypeNone = 0,
	SZMessageTypeMove = 1,
	SZMessageTypeNewEgg = 2,
	SZMessageTypeGameStart = 3
};

typedef NS_ENUM(char, SZRemoteMoveType) {
	SZRemoteMoveTypeNone = 0,
	SZRemoteMoveTypeLeft = 1,
	SZRemoteMoveTypeRight = 2,
	SZRemoteMoveTypeDown = 3,
	SZRemoteMoveTypeRotateClockwise = 4,
	SZRemoteMoveTypeRotateAnticlockwise = 5,
};

typedef struct {
	SZMessageType messageType;
} SZMessage;

typedef struct {
	SZMessage message;
	SZRemoteMoveType moveType;
} SZMoveMessage;

typedef struct {
	SZMessage message;
	char eggColour;
} SZNewEggMessage;

static NSString * const SZSessionId = @"com.simianzombie.superfoulegg";
static NSString * const SZDisplayName = @"Player";

@implementation SZNetworkSession

+ (SZNetworkSession *)sharedSession {
	static SZNetworkSession *sharedSession = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		sharedSession = [[SZNetworkSession alloc] init];
	});

	return sharedSession;
}

- (id)init {
	if ((self = [super init])) {

	}

	return self;
}

- (void)dealloc {
	[_session release];

	[super dealloc];
}

- (void)start {
	[_session release];

	_session = [[GKSession alloc] initWithSessionID:SZSessionId displayName:SZDisplayName sessionMode:GKSessionModePeer];
	_session.delegate = self;
	_session.available = YES;

	[_session setDataReceiveHandler:self withContext:nil];
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error {

}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error {

}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID {
	[session acceptConnectionFromPeer:peerID error:nil];
}

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {
	switch (state) {
		case GKPeerStateAvailable:
			[session connectToPeer:peerID withTimeout:20];
			break;
		case GKPeerStateConnected:

			_isServer = ([peerID compare:_session.peerID] == NSOrderedAscending);

			if (_isServer) {
				_isRunning = YES;

				SZEggBase *egg1 = [[SZEggFactory sharedFactory] newEggForPlayerNumber:2];
				SZEggBase *egg2 = [[SZEggFactory sharedFactory] newEggForPlayerNumber:2];

				[self sendNewEgg:egg1];
				[self sendNewEgg:egg2];

				[self sendGameStart];
			}

			break;
		case GKPeerStateConnecting:
			break;
		case GKPeerStateDisconnected:
			break;
		case GKPeerStateUnavailable:
			break;
	}
}

- (void)receiveData:(NSData *)data
		   fromPeer:(NSString *)peer
		  inSession:(GKSession *)session
			context:(void *)context {

	SZMessage *message = (SZMessage *)[data bytes];
	
	switch (message->messageType) {
		case SZMessageTypeMove:
			[self parseMoveMessage:(SZMoveMessage *)[data bytes]];
			break;
		case SZMessageTypeNewEgg:
			[self parseNewEggMessage:(SZNewEggMessage *)[data bytes]];
			break;
		case SZMessageTypeGameStart:

			_isRunning = YES;

			break;
		case SZMessageTypeNone:
			break;
	}
}

- (void)parseNewEggMessage:(SZNewEggMessage *)message {
	[[SZEggFactory sharedFactory] addEggClassFromColour:message->eggColour];
}

- (void)parseMoveMessage:(SZMoveMessage *)moveMessage {
	switch (moveMessage->moveType) {
		case SZRemoteMoveTypeNone:
			break;
		case SZRemoteMoveTypeDown:
			[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteDropNotification object:nil];
			break;
		case SZRemoteMoveTypeLeft:
			[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteMoveLeftNotification object:nil];
			break;
		case SZRemoteMoveTypeRight:
			[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteMoveRightNotification object:nil];
			break;
		case SZRemoteMoveTypeRotateAnticlockwise:
			[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteRotateAnticlockwiseNotification object:nil];
			break;
		case SZRemoteMoveTypeRotateClockwise:
			[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteRotateClockwiseNotification object:nil];
			break;
	}
}

- (void)sendData:(NSData *)data {
	[_session sendDataToAllPeers:data withDataMode:GKSendDataReliable error:nil];
}

- (void)sendLiveBlockMoveLeft {
	SZMoveMessage message;

	message.message.messageType = SZMessageTypeMove;
	message.moveType = SZRemoteMoveTypeLeft;

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

- (void)sendLiveBlockMoveRight {
	SZMoveMessage message;

	message.message.messageType = SZMessageTypeMove;
	message.moveType = SZRemoteMoveTypeRight;

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

- (void)sendLiveBlockDrop {
	SZMoveMessage message;

	message.message.messageType = SZMessageTypeMove;
	message.moveType = SZRemoteMoveTypeDown;

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

- (void)sendLiveBlockRotateClockwise {
	SZMoveMessage message;

	message.message.messageType = SZMessageTypeMove;
	message.moveType = SZRemoteMoveTypeRotateClockwise;

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

- (void)sendLiveBlockRotateAnticlockwise {
	SZMoveMessage message;

	message.message.messageType = SZMessageTypeMove;
	message.moveType = SZRemoteMoveTypeRotateAnticlockwise;

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

- (void)sendNewEgg:(SZEggBase *)egg {
	SZNewEggMessage message;

	SZEggColour colour = [[SZEggFactory sharedFactory] colourOfEgg:egg];

	message.message.messageType = SZMessageTypeNewEgg;
	message.eggColour = colour;

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

- (void)sendGameStart {
	SZMessage message;

	message.messageType = SZMessageTypeGameStart;

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

@end
