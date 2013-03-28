#import "MBFieldViewBuilder.h"
#import "MBField.h"
#import "MBFieldAlignmentTypes.h"
#import "MBUtil.h"
#import <UIKit/UIKit.h>

@implementation MBFieldViewBuilder

-(UIView *)buildFieldView:(MBField *)field withMaxBounds:(CGRect)bounds {
    NOT_IMPLEMENTED;
    return nil;
}

-(UIView*)buildFieldView:(MBField*)field forTableCell:(UITableViewCell *)cell withMaxBounds:(CGRect) bounds {
    UIView *child = [self buildFieldView:field withMaxBounds:bounds] ;
    
    CGFloat width = child.frame.size.width;
    
    // Move all other child views to the left to make room on the right for the new child 
    for (UIView *subview in cell.contentView.subviews) {
        CGRect frame = subview.frame;
        frame.origin.x -= width;
        subview.frame = frame;
    }
    
    // Place new child on the right of other children
    CGFloat right = cell.bounds.size.width;
    CGRect frame = child.frame;
    
    // Adjust alignment for new child
    if ([C_FIELD_ALIGNMENT_CENTER isEqualToString:field.alignment]) {
        frame.origin.x = (right - width)/2;
    }
    else if ([C_FIELD_ALIGNMENT_RIGHT isEqualToString:field.alignment]) {
        frame.origin.x= right - width-10; //10 px Right Margin
    }
    // Center new child horizontally
    frame.origin.y = (cell.frame.size.height - frame.size.height) / 2; 
    child.frame = frame;
    child.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleWidth;
    
    [cell.contentView addSubview:child];
    
    return child;
}

-(UIView *)buildFieldView:(MBField *)field forParent:(UIView *)parent withMaxBounds:(CGRect)bounds {
    
    
    if ([parent isKindOfClass:[UITableViewCell class]]) {
        UITableViewCell *cell = (UITableViewCell*)parent;
        return [self buildFieldView:field forTableCell:cell withMaxBounds:bounds];
    }
    
    else if ([parent.superview isKindOfClass:[UITableViewCell class]]) {
        UITableViewCell *cell = (UITableViewCell *)parent.superview;
        return [self buildFieldView:field forTableCell:cell withMaxBounds:bounds];
    }
    
    else {
        UIView *result = [self buildFieldView:field withMaxBounds:bounds];
        [parent addSubview: result];
        return result;
    }
    
}

@end