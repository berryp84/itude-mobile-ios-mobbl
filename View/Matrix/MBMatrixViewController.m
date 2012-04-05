//
//  MBMatrixViewController.m
//  Core
//
//  Created by Frank van Eenbergen on 6/7/10.
//  Copyright 2010 Itude Mobile BV. All rights reserved.
//

#import "MBMatrixViewController.h"
#import "MBField.h"
#import "MBFieldTypes.h"
#import "MBPage.h"

#import "MBMatrixHeaderView.h"
#import "MBMatrixViewBuilder.h"
#import "MBMatrixCell.h"

#import "MBDocumentDiff.h"

// This is the width that is used for the accessoryView. It is taken into account when a view is navigatable
#define ACCESSORYVIEWWIDTH 15
#define ROW_CELLS @"row_cells"
#define ROW_TITLE @"row_title"
#define ROW_NAVIGABLE @"row_navigable"
#define ROW_NAVIGATION_STYLE @"row_navigation_style"

@interface MBMatrixViewController (hidden) 
- (CGFloat)calculateTotalWidthForColumnsInTables;
@end


@implementation MBMatrixViewController

@synthesize matrixPanel = _matrixPanel;
@synthesize headerView = _headerView;
@synthesize headerPanel = _headerPanel;
@synthesize columnsTotalWidth = _columnsTotalWidth;
@synthesize rows = _rows;
@synthesize matrixViewBuilder = _matrixViewBuilder;

-(void) initialize { 
	[self setMatrixViewBuilder:[MBMatrixViewBuilder sharedInstance]];
	self.tableView.sectionHeaderHeight = 0;
	self.tableView.backgroundColor = [UIColor clearColor];
}	

-(id) initWithStyle:(UITableViewStyle)style {

	if(self = [super initWithStyle:style]) {
		[self initialize];
	}
	return self;
}

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		[self initialize];
	}
	return self;
}

- (void) dealloc
{
	[_matrixPanel release];
	[_headerView release];
	[_headerPanel release];
	[_rows release];
	[_cellReferences release];
	[_matrixViewBuilder release];
	[super dealloc];
}

// The following methods are here so you van override them in a subclass
- (void) fieldWasSelected:(MBField *)field{}
- (void) styleMatrixCell:(MBMatrixCell*) cell{}
- (void) initializeTableViewCell:(UITableViewCell *)cell withIndexPath:(NSIndexPath *)indexPath{}


-(void) viewDidAppear:(BOOL)animated{
	// for landscape mode, make sure table columns are recalculated
	[self performSelector:@selector(createHeaderView) withObject:nil afterDelay:0];
}

- (void) createHeaderView {
	self.columnsTotalWidth = [self calculateTotalWidthForColumnsInTables];
	if (self.headerPanel) self.tableView.tableHeaderView = [self constructHeaderView];
}

-(UIView *) constructHeaderView{
	NSString *headerTitle = nil; 
	NSMutableArray *headerCells = [[[NSMutableArray alloc] init] autorelease];
	
	NSArray *headerFields = [self.headerPanel children];		
	for (MBField *field in headerFields) {
		if ([[field type] isEqualToString:C_FIELD_MATRIXTITLE]) {
			if ([field value] != nil) headerTitle = [field value];
			else headerTitle = [field label];
		} 
		else [headerCells addObject:[MBMatrixCell cellForField:field]];
	}
	
	CGFloat margin = 0;
	if (self.tableView.style == UITableViewStyleGrouped) margin = 10;
		
	// We need to calculate the rowWidth for the columns
	self.columnsTotalWidth = [self calculateTotalWidthForColumnsInTables];
	UIView *headerView = [self.matrixViewBuilder createHeaderUsingColumnTitles:headerCells 
															   withHeaderTitle:headerTitle
															  withColumnsWidth:self.columnsTotalWidth
																withTableWidth:self.tableView.frame.size.width
																	withMargin:margin];
	return headerView;
}
 

-(MBMatrixCell*) cellForField:(MBField*) field ofPage:(MBPage*) page {
	MBMatrixCell *cell = [MBMatrixCell cellForField:field];
	[cell setWidth:[field width]];
	[cell setHeight:[field height]];
	return cell;
}

-(void) updateMatrixCells:(NSArray*) cells {
	for(MBMatrixCell *matrixCell in cells) {
        // Update all cells. Also the hidden ones. Otherwise coloring will not appear. BINCKRETAILSLA-211
        //if (!matrixCell.hidden) {
            [matrixCell updateValue];
            [self styleMatrixCell: matrixCell];
		//}
	}
}

-(void) updateDecoratorsForRow:(MBPanel*) row usingIndex:(int) rowIndex {
	NSArray *rowFields = [row children];
	for (MBField *field in rowFields) {
		if ([[field type] isEqualToString:C_FIELD_MATRIXTITLE]) {
			if ([field value] != nil) [row setViewData:[field value] forKey:ROW_TITLE];
			else [row setViewData:[field label] forKey:ROW_TITLE];
		} 
		else if ([C_FIELD_BUTTON isEqualToString:field.type]){
			[row setViewData:@"TRUE" forKey:ROW_NAVIGABLE];
			[row setViewData:[field style] forKey:ROW_NAVIGATION_STYLE];
			NSString *key = [NSString stringWithFormat:@"%i", rowIndex];
			[_cellReferences setValue: field forKey: key];
		}
	}	
}

-(void) createMatrixCellsForRow:(MBPanel*) row usingIndex:(int) rowIndex {
	if(_cellReferences == nil) 	_cellReferences = [[NSMutableDictionary alloc] init];

	NSMutableArray *rowCells = [NSMutableArray array];
	[row setViewData:rowCells forKey:ROW_CELLS];
	[row setViewData:@"FALSE" forKey:ROW_NAVIGABLE];
	
	MBPage *page = [row page];
	NSArray *rowFields = [row children];
	for (MBField *field in rowFields) {
		if ([[field type] isEqualToString:C_FIELD_MATRIXCELL]) {
			MBMatrixCell *matrixcell = [self cellForField: field ofPage: page];
			[rowCells addObject:matrixcell];
			[self styleMatrixCell: matrixcell];
		}
	}
	[self updateDecoratorsForRow: row usingIndex:(int) rowIndex];
}

-(void) updateMatrixRows {
	int rowIdx = 0;
	for(MBPanel *row in _rows) {
		NSMutableArray *rowCells = [row viewDataForKey:ROW_CELLS];
		if(rowCells == nil) [self createMatrixCellsForRow: row usingIndex: rowIdx];
		else { 
			[self updateMatrixCells: rowCells];
			[self updateDecoratorsForRow: row usingIndex: rowIdx];
		}
		rowIdx++;
	}
}

// Create the cells
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	NSString *reuseId = @"mxrow";
	
	MBPanel *row = [_rows objectAtIndex:indexPath.row];
	NSMutableArray *rowCells = [row viewDataForKey:ROW_CELLS];
	NSString *rowTitle = [row viewDataForKey:ROW_TITLE];
	
	CGFloat margin = (tableView.style == UITableViewStyleGrouped?10:0);

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
	
	// Check if we can reuse the cell. If the number of columns does not match because some developer (no names)
	// decided to use a mixed number of columns in 1 matrix we simply cannot reuse the row. Bad for performance;
	// but the alternative is having a crash: so simply drop the cell and create a new one.
	if(cell != nil) {
		MBMatrixRowView *rowView = [cell.contentView.subviews objectAtIndex:0];
		
		NSInteger numberOfFields = [rowView.fields count];
		NSInteger numberOfRowCells = [rowCells count];
		if(numberOfFields != numberOfRowCells) {

			// The cells can be invisible in which case the number of fields and number of cells does not match. 
			// Just deleting the cell is verry bad for performance, so we add an additional check.
			NSInteger numberOfVisibleRowCells = 0;			
			for (MBMatrixCell *c in rowCells) {
				if (!c.hidden) {
					numberOfVisibleRowCells ++;
				}
			}
			
			if (numberOfFields != numberOfVisibleRowCells) {
				cell = nil;
			}
		}
	}
	
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:reuseId] autorelease];
		self.columnsTotalWidth = [self calculateTotalWidthForColumnsInTables];
		MBMatrixRowView *rowView = [self.matrixViewBuilder createRowForCells:rowCells 
																   withTitle:rowTitle 
													   withColumnsTotalWidth:self.columnsTotalWidth 
															  withTableWidth:self.tableView.frame.size.width 
																  withMargin:margin];
		[cell.contentView addSubview:rowView];
		cell.frame = rowView.frame;
		
		[self initializeTableViewCell: cell withIndexPath:indexPath];
	}
	else {
		MBMatrixRowView *rowView = [cell.contentView.subviews objectAtIndex:0];
		[rowView updateWithCells:rowCells withTitle:rowTitle];
	}

    
    // Determine if a cell can be selected or not
	BOOL navigable = [[row viewDataForKey:ROW_NAVIGABLE] boolValue];
    if (!navigable) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    cell.isAccessibilityElement = YES;
    cell.accessibilityLabel = rowTitle;
    
	return cell;
}

// Handle the selection of a Row
- (void) handleSelectionOfRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *key = [NSString stringWithFormat:@"%i", [indexPath row]];
	MBField *field = [_cellReferences objectForKey: key];
	[self fieldWasSelected:field];
	
	if (field && [field outcomeName]) {
		[field handleOutcome:[field outcomeName] withPathArgument: [field absoluteDataPath]];
	}
}
////////// 
// http://dev.itude.com/jira/browse/BINCKAPPS-500 Only works on iPad
-(UITableViewCellAccessoryType) tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath {
	MBPanel *row = [_rows objectAtIndex:indexPath.row];
	NSString *fieldstyle = [row viewDataForKey:ROW_NAVIGATION_STYLE];
	BOOL navigable = [[row viewDataForKey:ROW_NAVIGABLE] boolValue];
	if (navigable && [C_FIELD_STYLE_NAVIGATION isEqualToString:fieldstyle]) return UITableViewCellAccessoryDisclosureIndicator;
	else return UITableViewCellAccessoryNone;
}
/* This can also be used
-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	MBPanel *row = [_rows objectAtIndex:indexPath.row];
	NSString *fieldstyle = [row viewDataForKey:ROW_NAVIGATION_STYLE];
	BOOL navigable = [[row viewDataForKey:ROW_NAVIGABLE] boolValue];
	if (navigable && [C_FIELD_STYLE_NAVIGATION isEqualToString:fieldstyle]) cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	else cell.accessoryType = UITableViewCellAccessoryNone;
}*/
//////////

// Delegate method that listens to the selection of a row
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self handleSelectionOfRowAtIndexPath:indexPath];
}

// Calculate the height for a row
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	
	MBPanel *row = [_rows objectAtIndex:indexPath.row];		
	NSArray *rowFields = [row children];

	BOOL foundTitle = NO;
	BOOL foundCells = NO;
	
	for (MBField *field in rowFields) {
		
		if ([[field type] isEqualToString:C_FIELD_MATRIXTITLE]) {
			foundTitle = YES;
			// We only need to find one cell to calculate the height
			if (foundCells) {
				break;
			}
		} 
		else if ([[field type] isEqualToString:C_FIELD_MATRIXCELL]) {
			foundCells = YES;
			// We only need to find one title to calculate the height
			if (foundTitle) {
				break;
			}
		}						
	}		
	
	return [self.matrixViewBuilder calculateHeightForRowWithTitle:foundTitle withCells:foundCells];
}
 
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

-(NSInteger) tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
	return [_rows count];
}

- (void)setMatrixPanel:(MBPanel *)panel {
	if (_matrixPanel != panel) {
		[_matrixPanel release];
		_matrixPanel = panel;
		[_matrixPanel retain];
		
		NSArray *headers = [_matrixPanel childrenOfKind:[MBPanel class] filterUsingSelector:@selector(type) havingValue:C_MATRIXHEADER];
		
		if ([headers count]>0) {
			self.headerPanel = [headers objectAtIndex:0];
			self.tableView.tableHeaderView = [self constructHeaderView];
		}
		self.rows = [_matrixPanel childrenOfKind:[MBPanel class] filterUsingSelector:@selector(type) havingValue:C_MATRIXROW];
		[self updateMatrixRows];
		self.columnsTotalWidth = [self calculateTotalWidthForColumnsInTables];
	}
}

// Calculates the the total width for the header and the rows that is used to calculate column widths. 
// This is needed because when a row is navigatable, there has to be some space for the accessoryView 
// When there is no accessoryView, the total width of a table can be used so there is as much space as possible to
// draw the columns on.
- (CGFloat)calculateTotalWidthForColumnsInTables {
	
	BOOL navigateableCellFound = NO;
	CGFloat totalRowWidth = self.tableView.bounds.size.width;//frame.size.width;
	
	// Iterate trough all rows. If we find one that is navigatable, ajust the totalRowWidth to leave space for the accessoryView
	for (MBPanel *row in self.rows) {
		for (MBField *field in [row children]) {
			if ([C_FIELD_BUTTON isEqualToString:field.type]){
				// store field for retrieval in didSelectRowAtIndexPath
				navigateableCellFound = YES;
				break;
			}
		}
	}
	
	if (navigateableCellFound) {
		totalRowWidth -= ACCESSORYVIEWWIDTH;
	}
	
	return totalRowWidth;	
}

- (void) refreshMatrixData
{
	// Make sure that new cells will be created
	[self updateMatrixRows];
	[self.tableView reloadData];
}

-(UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	// The height is set below
	return [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 0.0f, 0.0f)] autorelease];	
}

// Need to call to pad the footer height otherwise the footer collapses
// TODO: Place this in the stylehandler!
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return section == [self numberOfSectionsInTableView:tableView]?0.0f:10.0f;
}

@end
