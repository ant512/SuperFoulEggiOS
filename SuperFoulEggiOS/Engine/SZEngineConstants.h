/**
 * The number of eggs that can be live at one time.  We have to use a define
 * because we use this to initialise arrays and C is so quaintly old-fashioned.
 */
#define SZLiveEggCount 2
#define SZGridSize 96
#define SZMaximumPlayers 2
#define SZEggColourCount 6

/**
 * The number of garbage eggs represented by the face boulder.
 */
extern const int SZGarbageFaceBoulderValue;

/**
 * The number of garbage eggs represented by the large boulder.
 */
extern const int SZGarbageLargeBoulderValue;

/**
 * Dimensions of an egg.  Eggs are square.
 */
extern const int SZEggSize;

/**
 * Number of iterations before eggs drop when automatic dropping mode is
 * active.
 */
extern const int SZAutoDropTime;

/**
 * The bonus given for each successive chain sequenced together.
 */
extern const int SZChainSequenceGarbageBonus;

/**
 * The maximum speed at which live eggs can be forced to drop, measured in
 * iterations.
 */
extern const int SZMaximumDropSpeed;

/**
 * The minimum speed at which live eggs can be forced to drop, measured in
 * iterations.
 */
extern const int SZMinimumDropSpeed;

/**
 * The current drop speed is multiplied by this to produce the number of
 * iterations required until the live eggs are forced to drop.
 */
extern const int SZDropSpeedMultiplier;

extern const int SZGridWidth;
extern const int SZGridHeight;
extern const int SZGridEntryY;
extern const int SZChainLength;

extern NSString * const SZRemoteMoveLeftNotification;
extern NSString * const SZRemoteMoveRightNotification;
extern NSString * const SZRemoteMoveDownNotification;
extern NSString * const SZRemoteDropNotification;
extern NSString * const SZRemoteRotateClockwiseNotification;
extern NSString * const SZRemoteRotateAnticlockwiseNotification;
extern NSString * const SZRemoteEggDeliveryNotification;
extern NSString * const SZRemoteStartGameNotification;
extern NSString * const SZRemoteStartRoundNotification;
extern NSString * const SZRemoteReadyForNextEggNotification;
