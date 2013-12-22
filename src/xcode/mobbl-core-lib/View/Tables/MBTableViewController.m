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
//  Note: [self.view viewWithTag:100] = fontMenu

#import "MBRowViewBuilder.h"
#import "MBPanelViewBuilder.h"
#import "MBTableViewController.h"
#import "MBPanel.h"
#import "MBField.h"
#import "MBForEachItem.h"
#import "MBViewBuilderFactory.h"
#import "MBFieldDefinition.h"
#import "MBPage.h"
#import "MBPickerController.h"
#import "MBPickerPopoverController.h"
#import "MBDevice.h"
#import "MBDatePickerController.h"
#import "MBDatePickerPopoverController.h"
#import "MBWebView.h"
#import "UIView+TreeWalker.h"
#import "MBFontCustomizer.h"
#import "MBRowViewBuilderFactory.h"
#import "MBFieldTypes.h"
#import "MBRowTypes.h"

// Orientation support
#import "UIViewController+Rotation.h"
#import "UIViewController+Layout.h"

#define C_CELL_Y_MARGIN 4

// TODO: Get the font size and name from the styleHandler
@interface MBTableViewController()<MBFontCustomizerDelegate>

@property (nonatomic, retain) NSMutableDictionary *rowsByIndexPath;
@property (nonatomic, assign) NSInteger fontCustomizerFontSizeDifference;
@end

@implementation MBTableViewController

@synthesize styleHandler = _styleHandler;
@synthesize webViews = _webViews;
@synthesize finishedLoadingWebviews = _finishedLoadingWebviews;
@synthesize sections=_sections;
@synthesize page=_page;
@synthesize zoomable = _zoomable;
@synthesize rowsByIndexPath = _rowsByIndexPath;
@synthesize fontCustomizerFontSizeDifference = _fontCustomizerFontSizeDifference;

-(void) dealloc{
    // The following is REQUIRED to make sure no signal 10 is generated when a webview is still loading
    // while this controller is dealloced
    for(MBWebView *webView in [_webViews allValues]) {
        webView.delegate = nil;
    }
    //ios tries to update sublayers, which calls the related uitableview to refresh
    //Uitableview then calls its delegate which has already been deallocated (an instance of this class)
    //so we manually remove the uitableview from its delegate controller when the controller gets deallocated
    [self.view removeFromSuperview];
    [_webViews release];
    [_sections release];
    [_rowsByIndexPath release];
    
    [super dealloc];
}

-(void) viewDidLoad{
	[super viewDidLoad];
	self.styleHandler = [[MBViewBuilderFactory sharedInstance] styleHandler];
    self.rowsByIndexPath = [NSMutableDictionary dictionary];
	self.finishedLoadingWebviews = NO;
	self.webViews = [NSMutableDictionary dictionary];
	[self tableView].backgroundColor = [UIColor clearColor];
    self.fontCustomizerFontSizeDifference = 0;
    
    [self setupLayoutForIOS7];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self showFontCustomizer:self.zoomable];
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView{
	return [self.sections count];
}

-(NSInteger) tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)sectionNo {
	MBPanel *section = (MBPanel *)[self.sections objectAtIndex:(NSUInteger) sectionNo];
	NSMutableArray *rows = [section childrenOfKind:[MBPanel class]];
	return [rows count];
}

-(MBPanel *)getRowForIndexPath:(NSIndexPath *) indexPath {
	MBPanel *section = (MBPanel *)[self.sections objectAtIndex:(NSUInteger) indexPath.section];
	NSMutableArray *panels = [section childrenOfKind:[MBPanel class]];
	MBPanel *panel = [panels objectAtIndex:(NSUInteger) indexPath.row];
	return panel;
}

// This method returns nil by default so the default sectionHeader can be used.
// Register your own SectionPanelViewBuilder in the MBPanelViewBuilderFactory and return a custom view to override that,
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    MBPanel *panel = (MBPanel *)[self.sections objectAtIndex:section];
    CGRect bounds = CGRectMake(0, 0, tableView.frame.size.width, 0);
    return [[[MBViewBuilderFactory sharedInstance] panelViewBuilderFactory] buildPanelView:panel forParent:self.tableView withMaxBounds:bounds viewState: self.page.currentViewState];
}

-(UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	// The height is set below
	return [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 0.0f, 0.0f)] autorelease];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    MBPanel *panel = (MBPanel *)[self.sections objectAtIndex:section];
    id<MBPanelViewBuilder> builder = [[[MBViewBuilderFactory sharedInstance] panelViewBuilderFactory] builderForType:panel.type withStyle:panel.style];
    CGFloat height = [builder heightForPanel:panel];
    if (height > 0) {
        return height;
    }
    
    else if (!panel.title) {
        return 0;
    }
    
    // Automatic only works on iOS 5 and higher
    else if ([MBDevice iOSVersion] >= 5.0) {
        return UITableViewAutomaticDimension;
    }
    
    else if (self.tableView.style == UITableViewStyleGrouped) {
        return 44;
    }
    
    // Default height
    return 0;
}

// Need to call to pad the footer height otherwise the footer collapses
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 0.0f;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    MBWebView *webView = [self.webViews objectForKey:indexPath];
    if (webView) {
        NSString *heightString = [webView stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight;"];
        return [heightString floatValue] + C_CELL_Y_MARGIN * 2;
    }
    
    MBPanel *panel = [self getRowForIndexPath:indexPath];
    return [[[MBViewBuilderFactory sharedInstance] rowViewBuilderFactory] heightForPanel:panel atIndexPath:indexPath forTableView:tableView];
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    MBPanel *panel = [self getRowForIndexPath:indexPath];
    UITableViewCell *cell = [[[MBViewBuilderFactory sharedInstance] rowViewBuilderFactory] buildTableViewCellFor:panel forIndexPath:indexPath viewState:self.page.currentViewState forTableView:tableView];
    
    // Register any webViews in the cell
    [self.webViews removeObjectForKey:indexPath]; // Make sure no old webViews are retained
    for (UIView *subview in [cell subviewsOfClass:[MBWebView class]]) {
        MBWebView *webview = (MBWebView *)subview;
        webview.delegate = self;
        
        // Update the font for the fontCustomizer
        if (self.zoomable) {
            UIFont *currentFont = webview.font;
            UIFont *newFont = [UIFont fontWithName:currentFont.fontName size:currentFont.pointSize+self.fontCustomizerFontSizeDifference];
            [webview setFont:newFont];
            [webview refreshFont];
        }
        
        [self.webViews setObject:subview forKey:indexPath];
    }
    
    [self.rowsByIndexPath setObject:panel forKey:indexPath];
    
    return cell;
}


-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    MBPanel *panel = [self.rowsByIndexPath objectForKey:indexPath];
    
    // Handle the outcome on a Panel of type "ROW"
    if (panel.outcomeName) {
        NSString *path = [NSString stringWithFormat:@"%@/%@",[panel evaluatedDataPath], [panel path]];
        [panel handleOutcome:[panel outcomeName] withPathArgument:path];
    }
    
    //Dismiss keyboard
    [self.view endEditing:YES];
    
    
    [self.page resignFirstResponder];
    
    for (MBField *field in [panel childrenOfKind:[MBField class]]) {
        
        
        if ([C_FIELD_DROPDOWNLIST isEqualToString:field.type]) {
            [self fieldWasSelected:field];
            
            // iPad supports popovers, which are a nicer and better way to let the user make a choice from a dropdown list
            if ([MBDevice isPad]) {
                MBPickerPopoverController *picker = [[[MBPickerPopoverController alloc] initWithField:field] autorelease];
                picker.field = field;
                picker.delegate = self;
                UIView *cell = [tableView cellForRowAtIndexPath:indexPath];
                UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:picker];
                [popover presentPopoverFromRect:cell.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                picker.popover = popover;
                [popover release];
            }
            
            // On devices with a smaller screensize it's better to use a scrollWheel
            else {
                MBPickerController *pickerController = [[[MBPickerController alloc] initWithNibName:@"MBPicker" bundle:nil] autorelease];
                pickerController.field = field;
                pickerController.delegate = self;
                [field setViewData:pickerController forKey:@"pickerController"]; // let the page retain the picker controller
                UIView *superview = [[[[MBApplicationController currentInstance] viewManager] topMostVisibleViewController] view];
                [pickerController presentWithSuperview:superview];
            }
            
            
        } else if ([C_FIELD_DATETIMESELECTOR isEqualToString:field.type] ||
                   [C_FIELD_DATESELECTOR isEqualToString:field.type] ||
                   [C_FIELD_TIMESELECTOR isEqualToString:field.type] ||
                   [C_FIELD_BIRTHDATE isEqualToString:field.type]) {
            
            [self fieldWasSelected:field];
            
            if ([MBDevice isPad]) {
                MBDatePickerPopoverController *pickerController = [[[MBDatePickerPopoverController alloc] initWithNibName:@"MBDatePicker" bundle:nil] autorelease];
                [self configureDateTimePicker:pickerController forField:field];
                
                UIView *cell = [tableView cellForRowAtIndexPath:indexPath];
                UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:pickerController];
                
                [popover presentPopoverFromRect:cell.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                pickerController.popover = popover;
                [popover release];
                
            }
            
            else {
                MBDatePickerController *dateTimePickerController = [[[MBDatePickerController alloc] initWithNibName:@"MBDatePicker" bundle:nil] autorelease];
                [self configureDateTimePicker:dateTimePickerController forField:field];
                
                UIView *superView = [[[[MBApplicationController currentInstance] viewManager] topMostVisibleViewController] view];
                [dateTimePickerController presentWithSuperview:superView];
                
            }
            
            
        } else if (field && [field outcomeName]) {
            [self fieldWasSelected:field];
            
            // We check the field style because otherwise the outcome always gets triggered, even for actual buttons inside a row Ticket http://macserver.itude.com/jira/browse/MOBBL-509
            if ([C_FIELD_STYLE_NAVIGATION isEqualToString:[field style]]) {
                // this covers the case when field path has an indexed expressions while the commented one does not
                [field handleOutcome:[field outcomeName] withPathArgument:[field evaluatedDataPath]];
            }
            
        }
    }
}

// allows subclasses to attach behaviour to a field.
-(void) fieldWasSelected:(MBField *)field{
    (void)field;    // Prevent compiler warning of unused parameter
}

-(NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionNo{
    MBPanel *section = (MBPanel *)[self.sections objectAtIndex:(NSUInteger) sectionNo];
    return [section title];
}


// UIWebViewDelegate methods
-(void) webViewDidFinishLoad:(UIWebView *)webView{
	BOOL done = YES;
    
    // reset the frame to something small, somehow this triggers UIKit to recalculate the height
    webView.frame = CGRectMake(webView.frame.origin.x, webView.frame.origin.y, webView.frame.size.width, 1);
    [webView sizeToFit];
    
	for (MBWebView *w in [self.webViews allValues]){
		if (w.loading) {
			done=NO;
		}
	}
	
	if (done) {
		if (!self.finishedLoadingWebviews) {
			self.finishedLoadingWebviews = YES;
			[self.tableView reloadData];
		}
	}
}

-(void) rebuildView {
	
}

-(void)reloadAllWebViews{
    self.finishedLoadingWebviews = NO;
    for (MBWebView *webView in [self.webViews allValues]) {
        [webView reload];
    }
}


#pragma mark -
#pragma mark MBPickerControllerDelegate

// callback when pickerView value changes
- (void)fieldValueChanged:(MBField *)field {
    [self.tableView reloadData];
}


#pragma mark -
#pragma mark MBFontChangeListenerProtocol methods

-(void)showFontCustomizer:(BOOL)show {
    if (show) {
        
        UIViewController *parentViewcontroller = self.page.viewController;
        UIBarButtonItem *item = parentViewcontroller.navigationItem.rightBarButtonItem;
        
        if (item == nil || ![item isKindOfClass:[MBFontCustomizer class]]) {
            MBFontCustomizer *fontCustomizer = [[MBFontCustomizer new] autorelease];
            [fontCustomizer addToViewController:self animated:YES];
        }
    }
}


-(void)fontsizeIncreased:(id)sender {
    // The user may not increase the fontsize more than 4 points
    if (self.fontCustomizerFontSizeDifference <= 4) {
        self.finishedLoadingWebviews = NO;
        self.fontCustomizerFontSizeDifference+=1;
        for (MBWebView *webView in [self.webViews allValues]) {
            [webView refreshFont];
        }
        [self.tableView reloadData];
    }
}

-(void)fontsizeDecreased:(id)sender {
    // The user may not decrease the fontsize more than 4 points
    if (self.fontCustomizerFontSizeDifference >= -4) {
        self.finishedLoadingWebviews = NO;
        self.fontCustomizerFontSizeDifference-=1;
        for (MBWebView *webView in [self.webViews allValues]) {
            [webView refreshFont];
        }
        [self.tableView reloadData];
    }
}


#pragma mark -
#pragma mark Util

- (void)configureDateTimePicker:(MBDatePickerController *)dateTimePickerController forField:(MBField *)field {
    dateTimePickerController.field = field;
    dateTimePickerController.delegate = self;
    
    [field setViewData:dateTimePickerController forKey:@"datePickerController"]; // let the page retain the pickerController
    
    // Determine the datePickerModeStyle
    UIDatePickerMode datePickerMode = UIDatePickerModeDateAndTime;
    if ([C_FIELD_DATESELECTOR isEqualToString:field.type] || [C_FIELD_BIRTHDATE isEqualToString:field.type]) {
        datePickerMode = UIDatePickerModeDate;
    } else if ([C_FIELD_TIMESELECTOR isEqualToString:field.type]) {
        datePickerMode = UIDatePickerModeTime;
    }
    dateTimePickerController.datePickerMode = datePickerMode;
    
    if ([C_FIELD_BIRTHDATE isEqualToString:field.type]) {
        dateTimePickerController.maximumDate = [NSDate date];
    }
}


@end
