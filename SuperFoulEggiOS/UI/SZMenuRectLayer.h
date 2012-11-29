#import <Foundation/Foundation.h>

#import "cocos2d.h"
#import "CCLayer.h"

@interface SZMenuRectLayer : CCLayer {
	NSUInteger _selectedGroupIndex;
	NSMutableArray *_rectangleGroups;
	NSMutableArray *_selectedRectangleIndexes;
}

@property (readonly, retain, nonatomic) NSMutableArray *rectangleGroups;
@property (readonly, retain, nonatomic) NSMutableArray *selectedRectangleIndexes;
@property (readwrite, nonatomic) NSUInteger selectedGroupIndex;

- (NSUInteger)selectedIndexInGroup:(NSUInteger)groupIndex;
- (BOOL)selectRectangleAtPoint:(CGPoint)point;
- (void)clearSelectionInGroup:(int)groupIndex;

@end
