#import "SZNetworkSession.h"
#import "SZEngineConstants.h"
#import "SZEggFactory.h"
#import "SZEggBase.h"
#import "SZSettings.h"
#import "SZEggFactory.h"

typedef NS_ENUM(char, SZNetworkMessageType) {
	SZNetworkMessageTypeNone = 0,
	SZNetworkMessageTypeMove = 1,
	SZNetworkMessageTypeStartGame = 2,
	SZNetworkMessageTypeStartRound = 3,
	SZNetworkMessageTypeReadyForNextEgg = 4
};

typedef struct {
	SZNetworkMessageType messageType;
	int from;
	int to;
} SZNetworkMessage;

typedef struct {
	SZNetworkMessage message;
	SZBlockMoveType moveType;
} SZMoveMessage;

typedef struct {
	SZNetworkMessage message;
	char speed;
	char height;
	char eggColours;
	char gamesPerMatch;
	int randomEggSeed;
} SZStartGameMessage;

typedef struct {
	SZNetworkMessage message;
	int randomEggSeed;
} SZRoundStartMessage;

typedef struct {
	SZNetworkMessage message;
	char playerNumber;
} SZReadyForNextEggMessage;

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

- (void)dealloc {
	[_session release];
	[_highestPeerId release];
	[_nextEggAcknowledgements release];

	[super dealloc];
}

- (void)startWithPlayerCount:(NSUInteger)playerCount {

	_playerCount = playerCount;

	[_session release];
	[_highestPeerId release];
	_highestPeerId = nil;

	_session = [[GKSession alloc] initWithSessionID:SZSessionId displayName:SZDisplayName sessionMode:GKSessionModePeer];
	_session.delegate = self;
	_session.available = YES;

	_highestPeerId = [_session.peerID retain];

	NSLog(@"%@", _session.peerID);

	[_session setDataReceiveHandler:self withContext:nil];

	_voteCount = 0;
	
	_state = SZNetworkSessionStateWaitingForPeers;

	[_nextEggAcknowledgements release];
	_nextEggAcknowledgements = [[NSMutableDictionary dictionary] retain];
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

			if ([_highestPeerId compare:peerID] == NSOrderedAscending) {
				[_highestPeerId release];
				_highestPeerId = [peerID retain];
			}

			if ([session peersWithConnectionState:GKPeerStateConnected].count == _playerCount - 1) {
				_state = SZNetworkSessionStateGatheredPeers;
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
		   fromPeer:(NSString *)peerId
		  inSession:(GKSession *)session
			context:(void *)context {

	SZNetworkMessage *message = (SZNetworkMessage *)[data bytes];

	switch (message->messageType) {
		case SZNetworkMessageTypeMove:
			[self parseMoveMessage:(SZMoveMessage *)[data bytes] peerId:peerId];
			break;
		case SZNetworkMessageTypeStartGame:
			[self parseStartGameMessage:(SZStartGameMessage *)[data bytes] peerId:peerId];
			break;
		case SZNetworkMessageTypeStartRound:
			[self parseStartRoundMessage:(SZRoundStartMessage *)[data bytes] peerId:peerId];
			break;
		case SZNetworkMessageTypeReadyForNextEgg:
			[self parseReadyForNextEggMessage:(SZReadyForNextEggMessage *)[data bytes] peerId:peerId];
			break;
		case SZNetworkMessageTypeNone:
			break;
	}
}

- (void)parseReadyForNextEggMessage:(SZReadyForNextEggMessage *)message peerId:(NSString *)peerId {
	
	NSLog(@"Received ready for next egg message");

	NSNumber *playerNumber = @(message->playerNumber);

	if (_nextEggAcknowledgements[playerNumber]) {
		_nextEggAcknowledgements[playerNumber] = @([_nextEggAcknowledgements[playerNumber] intValue] + 1);
	} else {
		_nextEggAcknowledgements[playerNumber] = @1;
	}

	int count = [_nextEggAcknowledgements[playerNumber] intValue];

	if (count == [_session peersWithConnectionState:GKPeerStateConnected].count + 1) {

		NSLog(@"Player %@ is ready for a new egg", playerNumber);

		[_nextEggAcknowledgements removeObjectForKey:playerNumber];

		if (![_highestPeerId isEqualToString:_session.peerID]) {
			playerNumber = @(1 - message->playerNumber);
		}

		[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteReadyForNextEggNotification object:nil userInfo:@{ @"PlayerNumber": playerNumber }];
	}
}

- (void)parseMoveMessage:(SZMoveMessage *)moveMessage peerId:(NSString *)peerId {
	switch (moveMessage->moveType) {
		case SZBlockMoveTypeDown:
			[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteMoveDownNotification object:nil];
			break;
		case SZBlockMoveTypeLeft:
			[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteMoveLeftNotification object:nil];
			break;
		case SZBlockMoveTypeRight:
			[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteMoveRightNotification object:nil];
			break;
		//case SZRemoteMoveTypeDrop:
		//	[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteDropNotification object:nil];
		//	break;
		case SZBlockMoveTypeRotateAnticlockwise:
			[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteRotateAnticlockwiseNotification object:nil];
			break;
		case SZBlockMoveTypeRotateClockwise:
			[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteRotateClockwiseNotification object:nil];
			break;
	}
}

- (void)parseStartGameMessage:(SZStartGameMessage *)message peerId:(NSString *)peerId {

	NSLog(@"Received start game message");

	NSAssert(_state == SZNetworkSessionStateGatheredPeers || _state == SZNetworkSessionStateWaitingForGameStart, @"Illegal state when receiving start message");

	++_voteCount;

	if ([peerId isEqualToString:_highestPeerId]) {
		[SZSettings sharedSettings].height = message->height;
		[SZSettings sharedSettings].eggColours = message->eggColours;
		[SZSettings sharedSettings].speed = message->speed;
		[SZSettings sharedSettings].gamesPerMatch = message->gamesPerMatch;
		[SZSettings sharedSettings].randomEggSeed = message->randomEggSeed;
	}

	if (_voteCount == [_session peersWithConnectionState:GKPeerStateConnected].count + 1) {
		_state = SZNetworkSessionStateActive;

		_voteCount = 0;

		[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteStartGameNotification object:nil];
	}
}

- (void)parseStartRoundMessage:(SZRoundStartMessage *)message peerId:(NSString *)peerId {

	NSLog(@"Received start round message");

	if (_state != SZNetworkSessionStateWaitingForRoundStart) _voteCount = 0;

	_state = SZNetworkSessionStateWaitingForRoundStart;

	++_voteCount;
	
	if ([peerId isEqualToString:_highestPeerId]) {
		[SZSettings sharedSettings].randomEggSeed = message->randomEggSeed;

		NSLog(@"Seed: %d", message->randomEggSeed);
	}

	if (_voteCount == [_session peersWithConnectionState:GKPeerStateConnected].count + 1) {

		_voteCount = 0;

		[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteStartRoundNotification object:nil];

		_state = SZNetworkSessionStateActive;

		NSLog(@"Round started");
	}
}

- (void)sendData:(NSData *)data {
	[_session sendDataToAllPeers:data withDataMode:GKSendDataReliable error:nil];
}

- (void)sendStartRound {

	NSLog(@"Sending round message");

	SZRoundStartMessage message;

	message.message.messageType = SZNetworkMessageTypeStartRound;
	message.randomEggSeed = rand();

	[self parseStartRoundMessage:&message peerId:_session.peerID];

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

- (void)sendStartGame {

	NSLog(@"%d", _state);

	NSLog(@"Sending start game message");

	NSAssert(_state == SZNetworkSessionStateGatheredPeers, @"Illegal state when trying to start game");

	_state = SZNetworkSessionStateWaitingForGameStart;

	SZStartGameMessage message;

	message.message.messageType = SZNetworkMessageTypeStartGame;
	message.eggColours = [SZSettings sharedSettings].eggColours;
	message.height = [SZSettings sharedSettings].height;
	message.gamesPerMatch = [SZSettings sharedSettings].gamesPerMatch;
	message.speed = [SZSettings sharedSettings].speed;
	message.randomEggSeed = rand();

	[self parseStartGameMessage:&message peerId:_session.peerID];

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];

	NSLog(@"Start game sent");
}

- (void)sendBlockMove:(SZBlockMoveType)move fromPlayerNumber:(int)from {
	SZMoveMessage message;

	message.message.messageType = SZNetworkMessageTypeMove;
	message.message.from = from;
	message.message.to = from;
	message.moveType = move;
	
	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

- (void)sendReadyForNextEgg:(char)playerNumber {
	SZReadyForNextEggMessage message;

	message.message.messageType = SZNetworkMessageTypeReadyForNextEgg;

	// Player 0 on the top peer is player 1 on the other peer.  This will need
	// to be more complex to support more than two players.
	
	if ([_session.peerID isEqualToString:_highestPeerId]) {
		message.playerNumber = playerNumber;
	} else {
		message.playerNumber = 1 - playerNumber;
	}

	[self parseReadyForNextEggMessage:&message peerId:_session.peerID];

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

@end
