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

#import "MBNewRowViewBuilder.h"
#import "MBComponentContainer.h"
#import "MBFieldTypes.h"
#import "MBField.h"
#import "MBFieldViewBuilderFactory.h"
#import "MBViewBuilderFactory.h"
#import "MBDevice.h"
#import "MBPanel.h"
#import "StringUtilities.h"

@implementation MBNewRowViewBuilder

- (UITableViewCell *)cellForTableView:(UITableView *)tableView withType:(NSString *)cellReuseIdentifier style:(UITableViewCellStyle)cellstyle panel:(MBPanel *)panel {
    
    // Try to acquire an already allocated cell, in lieu of allocating a new one.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: cellReuseIdentifier];
    
    // Build a cell is none was available
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:cellstyle reuseIdentifier:cellReuseIdentifier] autorelease];
        cell.contentView.autoresizingMask= UIViewAutoresizingFlexibleWidth;
    }
    
    // Reset some properties if a already allocated cell is reused
    else {
        cell.accessoryView = nil;
        for(UIView *vw in cell.contentView.subviews) [vw removeFromSuperview];
        cell.textLabel.text = nil;
        cell.detailTextLabel.text = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (UITableViewCell *)buildCellForRow:(MBPanel *)panel forTableView:(UITableView *)tableView {
    NSString *cellReuseIdentifier = [self cellReuseIdentifierForRow:panel];
    UITableViewCellStyle style = [self tableViewCellStyleForRow:panel];
    return [self cellForTableView:tableView withType:cellReuseIdentifier style:style panel:panel];
}

- (UITableViewCell *)buildTableViewCellFor:(MBPanel *)panel forIndexPath:(NSIndexPath *)indexPath viewState:(MBViewState)viewState forTableView:(UITableView *)tableView
{
    UITableViewCell *cell = [self buildCellForRow:panel forTableView:tableView];
    
    // Loop through the fields in the row to build the content of the cell
    for(MBComponent *child in [panel children]){
        if ([child isKindOfClass:[MBField class]]) {
            MBField *field = (MBField *)child;
            field.responder = nil;
            if ([field.definition isPreConditionValid:panel.document currentPath:[field absoluteDataPath]]) {
                [[[MBViewBuilderFactory sharedInstance] fieldViewBuilderFactory] buildFieldView:field forParent:cell withMaxBounds:cell.bounds];
            }
        }
    }
    
    // If the bounds are set for a field with buttons, then the view get's all messed up.
    if (![MBDevice isPad]) {
        CGRect bounds = cell.bounds;
        bounds.size.width = tableView.frame.size.width;
        cell.bounds = bounds;
    }
    
    cell.selectionStyle = [self cellSelectionStyleForRow:panel];
    cell.accessoryType = [self cellAccesoryTypeForRow:panel];
    
    return cell;
}

-(CGFloat)heightForPanel:(MBPanel *)panel atIndexPath:(NSIndexPath *)indexPath forTableView:(UITableView *)tableView
{
    CGFloat height = 44;
    UITableViewCell *cell = [self buildCellForRow:panel forTableView:tableView];
    
    // Loop through the fields in the row to determine the size of multiline text cells
    for(MBComponent *child in [panel children]){
        if ([child isKindOfClass:[MBField class]]) {
            MBField *field = (MBField *)child;

            CGFloat childHight = [[[MBViewBuilderFactory sharedInstance] fieldViewBuilderFactory] heightForField:field forParent:cell withMaxBounds:cell.bounds];
            
            // Fallback scenario (for backwards compatibility)
            if (childHight == 0) {
                childHight = [self.styleHandler heightForField:field forTableView:tableView];
            }
            
            
            if (childHight > height){
                height = childHight;
            }
            
        }
    }
    
    return height;
}

- (UITableViewCellStyle) tableViewCellStyleForRow:(MBPanel *)panel {
    UITableViewCellStyle style = UITableViewCellStyleDefault;
    
    // Loop through the fields in the row to determine the type and style of the cell
    for(MBComponent *child in [panel children]){
        if ([child isKindOfClass:[MBField class]]) {
            MBField *field = (MBField *)child;
            if ([field.definition isPreConditionValid:panel.document currentPath:[field absoluteDataPath]]) {
                
                if ([C_FIELD_LABEL isEqualToString:field.type] ||
                    [C_FIELD_TEXT isEqualToString:field.type]){
                    // Default
                }
                
                if ([self fieldIsDropdownListType:field]) {
                    style = UITableViewCellStyleValue1;
                }
                
                if ([C_FIELD_SUBLABEL isEqualToString:field.type]){
                    style = UITableViewCellStyleSubtitle;
                }
            }
        }
    }
    
    return style;
}

- (NSString *) cellReuseIdentifierForRow:(MBPanel *)panel {
    NSString *type = panel.type;
    
    // Loop through the fields in the row to determine the type
    for(MBComponent *child in [panel children]){
        if ([child isKindOfClass:[MBField class]]) {
            MBField *field = (MBField *)child;
            if ([field.definition isPreConditionValid:panel.document currentPath:[field absoluteDataPath]]) {
                
                if ([self fieldIsDropdownListType:field]) {
                    type = C_DROPDOWNLISTCELL;
                }
                
                if ([C_FIELD_SUBLABEL isEqualToString:field.type]){
                    type = C_SUBTITLECELL;
                }
                
            }
        }
    }
    
    return type;
}

- (UITableViewCellSelectionStyle)cellSelectionStyleForRow:(MBPanel *)panel {
    return ([panel outcomeName]) ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
}

- (UITableViewCellAccessoryType)cellAccesoryTypeForRow:(MBPanel *)panel {
    
    // Always show an disclosureIndicator if a cell is clickable/navigatable
    if ([panel outcomeName]) {
        return UITableViewCellAccessoryDisclosureIndicator;
    }
    
    // Loop through the fields in the row to determine the accessoryType
    for(MBComponent *child in [panel children]){
        if ([child isKindOfClass:[MBField class]]) {
            MBField *field = (MBField *)child;
            if ([field.definition isPreConditionValid:panel.document currentPath:[field absoluteDataPath]] && [self fieldIsDropdownListType:field]) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        }
    }
    
    // Default is no accessoryIndicator
    return UITableViewCellAccessoryNone;
}


#pragma mark -
#pragma mark Util

- (BOOL)fieldIsDropdownListType:(MBField *)field {
    return ([C_FIELD_DROPDOWNLIST isEqualToString:field.type] ||
            [C_FIELD_DATETIMESELECTOR isEqualToString:field.type] ||
            [C_FIELD_DATESELECTOR isEqualToString:field.type] ||
            [C_FIELD_TIMESELECTOR isEqualToString:field.type] ||
            [C_FIELD_BIRTHDATE isEqualToString:field.type]);
}

@end
