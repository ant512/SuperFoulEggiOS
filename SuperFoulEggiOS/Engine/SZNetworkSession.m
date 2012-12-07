#import "SZNetworkSession.h"
#import "SZEngineConstants.h"
#import "SZEggFactory.h"
#import "SZEggBase.h"
#import "SZSettings.h"

typedef NS_ENUM(char, SZMessageType) {
	SZMessageTypeNone = 0,
	SZMessageTypeMove = 1,
	SZMessageTypeEggVote = 2
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
	char eggColour1;
	char eggColour2;
	int voteNumber;
} SZEggPairVoteMessage;

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
	[_currentVotes release];

	[super dealloc];
}

- (void)startWithPlayerCount:(NSUInteger)playerCount {

	_playerCount = playerCount;

	[_session release];
	[_currentVotes release];

	_session = [[GKSession alloc] initWithSessionID:SZSessionId displayName:SZDisplayName sessionMode:GKSessionModePeer];
	_session.delegate = self;
	_session.available = YES;

	[_session setDataReceiveHandler:self withContext:nil];

	_currentVotes = [[NSMutableDictionary dictionary] retain];
	
	_eggVoteNumber = 0;
	_isWaitingForVotes = NO;
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

			if ([session peersWithConnectionState:GKPeerStateConnected].count == _playerCount - 1) {
				[self sendEggPairVote];
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

	SZMessage *message = (SZMessage *)[data bytes];

	switch (message->messageType) {
		case SZMessageTypeMove:
			[self parseMoveMessage:(SZMoveMessage *)[data bytes]];
			break;
		case SZMessageTypeEggVote:
			[self parseEggPairVoteMessage:(SZEggPairVoteMessage *)[data bytes] peerId:peerId];
			break;
		case SZMessageTypeNone:
			break;
	}
}

- (void)sendEggPairVote {

	if (_isWaitingForVotes) return;
	if ([_session peersWithConnectionState:GKPeerStateConnected].count < _playerCount - 1) return;
	
	_isWaitingForVotes = YES;

	SZEggPairVoteMessage message;

	message.message.messageType = SZMessageTypeEggVote;
	message.eggColour1 = rand() % [SZSettings sharedSettings].eggColours;
	message.eggColour2 = rand() % [SZSettings sharedSettings].eggColours;
	message.voteNumber = _eggVoteNumber;

	_currentVotes[_session.peerID] = @[ @(message.eggColour1), @(message.eggColour2) ];

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

- (void)parseEggPairVoteMessage:(SZEggPairVoteMessage *)message peerId:(NSString *)peerId {

	NSAssert(message->voteNumber <= _eggVoteNumber, @"Peer voting for a future vote number");

	// If we've already voted on an egg we don't want to vote again.  If we do
	// we'll end up with every client replying to every vote, which in turn will
	// prompt votes, and prompt votes, ad infinitum.
	if (message->voteNumber < _eggVoteNumber) return;

	_currentVotes[peerId] = @[ @(message->eggColour1), @(message->eggColour2) ];

	NSLog(@"%d", [_session peersWithConnectionState:GKPeerStateConnected].count);

	if (_currentVotes.count == [_session peersWithConnectionState:GKPeerStateConnected].count) {

		// At this point I'd intended to count the votes and choose the colour
		// with the most votes or, in the case of a tie, the vote from the peer
		// with the highest peer ID.  Then I realised that I could ignore the
		// count and just use the vote from the highest peer ID.  It's a
		// democracy inspired by the American voting system!

		NSString *winner = nil;

		for (NSString *peer in _currentVotes) {
			if ([peer compare:winner] == NSOrderedAscending) {
				winner = peer;
			}
		}

		[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteEggDeliveryNotification object:_currentVotes[winner]];

		[_currentVotes removeAllObjects];
		++_eggVoteNumber;
	}
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

@end
