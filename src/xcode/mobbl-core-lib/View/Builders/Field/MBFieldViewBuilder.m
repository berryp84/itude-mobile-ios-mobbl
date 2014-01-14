/*
 * (C) Copyright Itude Mobile B.V., The Netherlands.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
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
    
    CGFloat margin = 10;
    CGFloat width = child.frame.size.width;
    
    // Move all other child views to the left to make room on the right for the new child 
    for (UIView *subview in cell.contentView.subviews) {
        CGRect frame = subview.frame;
        frame.origin.x -= width+margin;
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
    
    [cell.contentView addSubview:child];
    
    return child;
}

-(UIView *)buildFieldView:(MBField *)field forParent:(UIView *)parent withMaxBounds:(CGRect)bounds {
    
    if ([parent isKindOfClass:[UITableViewCell class]]) {
        UITableViewCell *cell = (UITableViewCell*)parent;
        return [self buildFieldView:field forTableCell:cell withMaxBounds:cell.contentView.bounds];
    }
    else {
        UIView *result = [self buildFieldView:field withMaxBounds:bounds];
        [parent addSubview: result];
        return result;
    }
    
}

- (CGFloat)heightForField:(MBField *)field forParent:(UIView *)parent withMaxBounds:(CGRect)bounds {
    // Returns 0 by default. Implement your own 
    return 0;
}

@end