#import <Foundation/Foundation.h>

#import "SZGridBase.h"

@implementation SZGridBase

- (id)init {
	if ((self = [super init])) {
		for (int i = 0; i < SZGridSize; ++i) {
			_data[i] = nil;
		}
	}
	
	return self;
}

- (void)dealloc {
	[self clear];
	[super dealloc];
}

- (void)clear {
	for (int i = 0; i < SZGridSize; ++i) {
		[_data[i] release];
		_data[i] = nil;
	}
}

- (SZEggBase *)eggAtX:(int)x y:(int)y {
	if (![self isValidCoordinateX:x y:y]) return nil;

	return _data[x + (y * SZGridWidth)];
}

- (void)moveEggFromSourceX:(int)sourceX sourceY:(int)sourceY toDestinationX:(int)destinationX destinationY:(int)destinationY {

	NSAssert([self isValidCoordinateX:sourceX y:sourceY], @"Invalid source co-ordinates supplied.");
	NSAssert([self isValidCoordinateX:destinationX y:destinationY], @"Invalid destination co-ordinates supplied.");

	if (sourceX == destinationX && sourceY == destinationY) return;

	int srcIndex = sourceX + (sourceY * SZGridWidth);
	int destIndex = destinationX + (destinationY * SZGridWidth);

	NSAssert(_data[destIndex] == nil, @"Attempt to move egg to non-empty grid location.");
	NSAssert(_data[srcIndex] != nil, @"Attempt to move nil egg to new location.");

	_data[destIndex] = _data[srcIndex];
	_data[srcIndex] = nil;

	[_data[destIndex] setX:destinationX andY:destinationY];
}

- (BOOL)isValidCoordinateX:(int)x y:(int)y {
	if (x < 0) return NO;
	if (x >= SZGridWidth) return NO;
	if (y < 0) return NO;
	if (y >= SZGridHeight) return NO;

	return YES;
}

- (void)addEgg:(SZEggBase *)egg x:(int)x y:(int)y {
	
	NSAssert([self eggAtX:x y:y] == nil, @"Attempt to add egg at non-empty grid location");
	
	int index = x + (y * SZGridWidth);
	_data[index] = [egg retain];
    
    [egg setX:x andY:y];
}

- (void)removeEggAtX:(int)x y:(int)y {
	int index = x + (y * SZGridWidth);
	
	SZEggBase *egg = _data[index];
	_data[index] = nil;
	[egg release];
}


- (int)heightOfColumnAtIndex:(int)index {

	NSAssert(index < SZGridWidth, @"Invalid column index supplied.");

	int height = 0;

	for (int y = SZGridHeight - SZGridEntryY + 1; y >= 0; --y) {
		SZEggBase *egg = [self eggAtX:index y:y];
		if (egg != nil && egg.state == SZEggStateNormal) {
			++height;
		} else {
			break;
		}
	}

	return height;
}

@end
