#import "SZNetworkSession.h"
#import "SZEngineConstants.h"
#import "SZEggFactory.h"
#import "SZEggBase.h"
#import "SZSettings.h"
#import "SZEggFactory.h"

typedef NS_ENUM(char, SZMessageType) {
	SZMessageTypeNone = 0,
	SZMessageTypeMove = 1,
	SZMessageTypeEggVote = 2,
	SZMessageTypeStartGame = 3,
	SZMessageTypeStartRound = 4
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

typedef struct {
	SZMessage message;
	char speed;
	char height;
	char eggColours;
	char gamesPerMatch;
} SZStartGameMessage;

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
	
	[self resetEggVotes];

	_voteCount = 0;
	
	_state = SZNetworkSessionStateWaitingForPeers;
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

	SZMessage *message = (SZMessage *)[data bytes];

	switch (message->messageType) {
		case SZMessageTypeMove:
			[self parseMoveMessage:(SZMoveMessage *)[data bytes] peerId:peerId];
			break;
		case SZMessageTypeEggVote:
			[self parseEggPairVoteMessage:(SZEggPairVoteMessage *)[data bytes] peerId:peerId];
			break;
		case SZMessageTypeStartGame:
			[self parseStartGameMessage:(SZStartGameMessage *)[data bytes] peerId:peerId];
			break;
		case SZMessageTypeStartRound:
			[self parseStartRoundMessage:(SZMessage *)[data bytes] peerId:peerId];
			break;
		case SZMessageTypeNone:
			break;
	}
}

- (void)resetEggVotes {
	_eggVoteColour1 = SZEggColourNone;
	_eggVoteColour2 = SZEggColourNone;
	_voteCount = 0;
	_eggVoteNumber = 0;
}

- (void)sendEggPairVote {

	if (_state != SZNetworkSessionStateActive) return;

	NSLog(@"Sending egg vote");

	SZEggPairVoteMessage message;

	message.message.messageType = SZMessageTypeEggVote;
	message.eggColour1 = SZEggColourRed + (rand() % [SZSettings sharedSettings].eggColours);
	message.eggColour2 = SZEggColourRed + (rand() % [SZSettings sharedSettings].eggColours);
	message.voteNumber = _eggVoteNumber;

	_state = SZNetworkSessionStateWaitingForEggVotes;

	[self parseEggPairVoteMessage:&message peerId:_session.peerID];

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

- (void)parseEggPairVoteMessage:(SZEggPairVoteMessage *)message peerId:(NSString *)peerId {

	NSAssert(_state == SZNetworkSessionStateWaitingForEggVotes || _state == SZNetworkSessionStateActive, @"Received unexpected egg vote");

	NSLog(@"Received egg vote");

	++_voteCount;

	// If we've already voted on an egg we don't want to vote again.  If we do
	// we'll end up with every client replying to every vote, which in turn will
	// prompt votes, and prompt votes, ad infinitum.
	if (message->voteNumber < _eggVoteNumber) {

		NSLog(@"Already voted");

		return;
	}

	if (message->voteNumber > _eggVoteNumber) {
		[self sendEggPairVote];
		++_eggVoteNumber;
	}

	if ([peerId isEqualToString:_highestPeerId]) {

		NSLog(@"Highest peer is %@", _highestPeerId);

		_eggVoteColour1 = message->eggColour1;
		_eggVoteColour2 = message->eggColour2;
	}

	NSAssert(message->voteNumber == _eggVoteNumber, @"Voting out of sync");

	NSLog(@"Peers: %d, votes: %d", [_session peersWithConnectionState:GKPeerStateConnected].count + 1, _voteCount);

	if (_voteCount == [_session peersWithConnectionState:GKPeerStateConnected].count + 1) {

		NSLog(@"Received all egg votes");

		// At this point I'd intended to count the votes and choose the colour
		// with the most votes or, in the case of a tie, the vote from the peer
		// with the highest peer ID.  Then I realised that I could ignore the
		// count and just use the vote from the highest peer ID.  It's a
		// democracy inspired by the American voting system!

		[[SZEggFactory sharedFactory] addEggPairColour1:_eggVoteColour1 colour2:_eggVoteColour2];

		++_eggVoteNumber;
		_voteCount = 0;
		
		_state = SZNetworkSessionStateActive;
	}
}

- (void)parseMoveMessage:(SZMoveMessage *)moveMessage peerId:(NSString *)peerId {
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

- (void)parseStartGameMessage:(SZStartGameMessage *)message peerId:(NSString *)peerId {

	NSLog(@"Received start game message");

	NSAssert(_state == SZNetworkSessionStateGatheredPeers || _state == SZNetworkSessionStateWaitingForGameStart, @"Illegal state when receiving start message");

	++_voteCount;

	if ([peerId isEqualToString:_highestPeerId]) {
		[SZSettings sharedSettings].height = message->height;
		[SZSettings sharedSettings].eggColours = message->eggColours;
		[SZSettings sharedSettings].speed = message->speed;
		[SZSettings sharedSettings].gamesPerMatch = message->gamesPerMatch;
	}

	if (_voteCount == [_session peersWithConnectionState:GKPeerStateConnected].count + 1) {
		_state = SZNetworkSessionStateActive;

		_voteCount = 0;

		[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteStartGameNotification object:nil];
	}
}

- (void)parseStartRoundMessage:(SZMessage *)message peerId:(NSString *)peerId {

	NSLog(@"Received start round message");

	_state = SZNetworkSessionStateWaitingForRoundStart;

	++_voteCount;

	if (_voteCount == [_session peersWithConnectionState:GKPeerStateConnected].count + 1) {
		_state = SZNetworkSessionStateActive;

		_voteCount = 0;

		[self resetEggVotes];

		[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteStartRoundNotification object:nil];
	}
}

- (void)sendData:(NSData *)data {
	[_session sendDataToAllPeers:data withDataMode:GKSendDataReliable error:nil];
}

- (void)sendStartRound {

	NSLog(@"Sending round message");

	_state = SZNetworkSessionStateWaitingForRoundStart;

	SZMessage message;

	message.messageType = SZMessageTypeStartRound;

	[self parseStartRoundMessage:&message peerId:_session.peerID];

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

- (void)sendStartGame {

	NSLog(@"%d", _state);

	NSLog(@"Sending start game message");

	NSAssert(_state == SZNetworkSessionStateGatheredPeers, @"Illegal state when trying to start game");

	_state = SZNetworkSessionStateWaitingForGameStart;

	SZStartGameMessage message;

	message.message.messageType = SZMessageTypeStartGame;
	message.eggColours = [SZSettings sharedSettings].eggColours;
	message.height = [SZSettings sharedSettings].height;
	message.gamesPerMatch = [SZSettings sharedSettings].gamesPerMatch;
	message.speed = [SZSettings sharedSettings].speed;

	[self parseStartGameMessage:&message peerId:_session.peerID];

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];

	NSLog(@"Start game sent");
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
