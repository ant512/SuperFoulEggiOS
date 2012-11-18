#import "MenuRectLayer.h"

@implementation MenuRectLayer

@synthesize rectangleGroups = _rectangleGroups;
@synthesize selectedRectangleIndexes = _selectedRectangleIndexes;
@synthesize selectedGroupIndex = _selectedGroupIndex;

- (id)init {
	if ((self = [super init])) {
		_rectangleGroups = [[NSMutableArray array] retain];
		_selectedRectangleIndexes = [[NSMutableArray array] retain];
		_selectedGroupIndex = 0;
	}

	return self;
}

- (void)dealloc {
	[_rectangleGroups release];
	[_selectedRectangleIndexes release];
	
	_rectangleGroups = nil;
	_selectedRectangleIndexes = nil;
	
	[super dealloc];
}

- (void)ensureRectangleIndexesExist {
	for (NSUInteger i = _selectedRectangleIndexes.count; i < _rectangleGroups.count; ++i) {
		[_selectedRectangleIndexes addObject:@0];
	}
}

- (BOOL)selectRectangleAtPoint:(CGPoint)point {

	for (NSArray *group in _rectangleGroups) {
		for (NSValue *value in group) {
			CGRect rect = [value CGRectValue];

			if (CGRectContainsPoint(rect, point)) {
				_selectedGroupIndex = [_rectangleGroups indexOfObject:group];
				
				int index = [group indexOfObject:value];
				
				[_selectedRectangleIndexes setObject:[NSNumber numberWithUnsignedInteger:index] atIndexedSubscript:_selectedGroupIndex];

				return YES;
			}
		}
	}

	return NO;
}

- (void)clearSelectionInGroup:(int)groupIndex {
	[_selectedRectangleIndexes setObject:@(-1) atIndexedSubscript:groupIndex];
}

- (NSUInteger)selectedIndexInGroup:(NSUInteger)groupIndex {
	[self ensureRectangleIndexesExist];
	return [[_selectedRectangleIndexes objectAtIndex:groupIndex] intValue];
}

- (void)draw {
    ccDrawColor4B(255, 255, 255, 255);
    glLineWidth(1);

	for (NSArray *group in _rectangleGroups) {
		
		NSUInteger groupIndex = [_rectangleGroups indexOfObject:group];
		
		for (NSValue *value in group) {
			CGRect rect = [value CGRectValue];
			
			NSUInteger rectangleIndex = [group indexOfObject:value];

			ccColor4F dark = ccc4f(0, 0, 0, 0.5);
			ccColor4F light = ccc4f(0.5, 0.5, 0.0, 0.5);

			ccColor4F colour = rectangleIndex == [self selectedIndexInGroup:groupIndex] ? light : dark;
			
			ccDrawRect(rect.origin, ccp(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height));
			
			ccDrawSolidRect(rect.origin, ccp(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height), colour);
		}
	}
}

@end
