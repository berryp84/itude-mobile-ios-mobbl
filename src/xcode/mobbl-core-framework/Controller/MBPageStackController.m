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

#import "MBMacros.h"
#import "MBPageStackController.h"
#import "MBPage.h"
#import "MBActivityIndicator.h"
#import "MBSpinner.h"
#import "MBStyleHandler.h"
#import "MBViewBuilderFactory.h"
#import "MBBasicViewController.h"
#import "MBViewManager.h"
#import "MBTransitionStyle.h"
#import "MBDialogController.h"
#import "MBLocalizationService.h"

#import <QuartzCore/QuartzCore.h>

#import "UIViewController+Rotation.h"
#import "UINavigationController+MBRebuilder.h"

@interface MBPageStackController(){
    // Public
	NSString *_name;
	NSString *_title;
	MBDialogController *_dialogController;
    UINavigationController *_navigationController;
    CGRect _bounds;
    
    // Private
	NSInteger _activityIndicatorCount;
	BOOL _temporary;
}
@property (nonatomic, assign) NSInteger activityIndicatorCount;
@property (nonatomic, assign, readonly) dispatch_semaphore_t navigationSemaphore;
@property (nonatomic, assign) BOOL needsRelease;

@property (nonatomic, assign) BOOL markedForReset;

-(void) clearSubviews;

@end

@implementation MBPageStackController

// Public
@synthesize name = _name;
@synthesize title = _title;
@synthesize dialogController = _dialogController;
@synthesize navigationController = _navigationController;

// Private
@synthesize bounds = _bounds;
@synthesize activityIndicatorCount = _activityIndicatorCount;

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	dispatch_release(_navigationSemaphore);

	[_name release];
    [_title release];
    [_dialogController release];
    [_navigationController release];
	[super dealloc];
}

-(id) initWithDefinition:(MBPageStackDefinition *)definition {
	if(self = [super init]) {
		self.name = definition.name;
		self.title = definition.title;
		self.navigationController = [[UINavigationController new] autorelease];
		self.activityIndicatorCount = 0;
		[self showActivityIndicator];
		_navigationSemaphore = dispatch_semaphore_create(1);
		self.needsRelease = false;
		self.markedForReset = true;
        [[[MBViewBuilderFactory sharedInstance] styleHandler] styleNavigationBar:self.navigationController.navigationBar];
	}
	return self;
    
}

- (id)initWithDefinition:(MBPageStackDefinition *)definition withDialogController:(MBDialogController *)parent {
    if(self = [self initWithDefinition:definition]) {
        self.dialogController = parent;
	}
	return self;
}

-(id) initWithDefinition:(MBPageStackDefinition*)definition page:(MBPage*) page bounds:(CGRect) bounds {
	if(self = [self initWithDefinition:definition]) {
        MBBasicViewController *controller = (MBBasicViewController*)page.viewController;
        controller.pageStackController = self;
        [self.navigationController setRootViewController:page.viewController];
        _bounds = bounds;
	}
	return self;
}



-(void)showPage:(MBPage *)page displayMode:(NSString *)displayMode transitionStyle:(NSString *)transitionStyle {
    
    if(displayMode != nil){
        DLog(@"PageStackController: showPage name=%@ pageStack=%@ mode=%@", page.pageName, _name, displayMode);
	}

    page.transitionStyle = transitionStyle;

	UINavigationController *nav = self.navigationController;
	MBBasicViewController *viewController = (MBBasicViewController*)[page.viewController retain];

	viewController.pageStackController = self;

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		dispatch_semaphore_wait(self.navigationSemaphore, DISPATCH_TIME_FOREVER);
		dispatch_async(dispatch_get_main_queue(), ^{

			// Apply transitionStyle for a regular page navigation
			id<MBTransitionStyle> style = [[[MBApplicationFactory sharedInstance] transitionStyleFactory] transitionForStyle:transitionStyle];
			[style applyTransitionStyleToViewController:nav forMovement:MBTransitionMovementPush];

			[viewController autorelease];
			self.needsRelease = true;


			if (self.markedForReset) {
				self.navigationController.viewControllers = [NSArray arrayWithObject:viewController];
				self.markedForReset = false;
			} else {


			// Replace the last page on the stack
			if([displayMode isEqualToString:@"REPLACE"]) {
				[nav replaceLastViewController:viewController];
				return;
			}
			
			// Regular navigation to new page
			else {
				[nav pushViewController:viewController animated:[style animated]];
			}
			}
			
			// This needs to be done after the page (viewController) is visible, because before that we have nothing to set the close button to
			[self setupCloseButtonForPage:page];
		});
		});

    
}

-(void)popPageWithTransitionStyle:(NSString *)transitionStyle animated:(BOOL)animated
{
	UINavigationController *nav = self.navigationController;
    
    // Apply transitionStyle for a regular page navigation
    if (transitionStyle) {
        id<MBTransitionStyle> style = [[[MBApplicationFactory sharedInstance] transitionStyleFactory] transitionForStyle:transitionStyle];
        [style applyTransitionStyleToViewController:nav forMovement:MBTransitionMovementPop];
        
        // Regular navigation to new page
        animated = [style animated];
    }
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		dispatch_semaphore_wait(self.navigationSemaphore, DISPATCH_TIME_FOREVER);
		dispatch_async(dispatch_get_main_queue(), ^{
			self.needsRelease = true;

			[nav popViewControllerAnimated:animated];
		});
	});
}

-(void) doRebuild {
	// Make sure we do this on the foreground! So:
	dispatch_async(dispatch_get_main_queue(), ^{
		[self rebuildPage:nil];
	});
}

-(void) rebuildPage:(id) args {
    [self.navigationController rebuild];
}


-(void)willActivate {
    DLog(@"Will show pageStackController with name %@", [self name]);
}

-(void) navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    [self willActivate];
}

-(void)didActivate {
    DLog(@"Did show pageStackController with name %@", [self name]);
}

-(void) navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
	_navigationController = viewController.navigationController;
    [self didActivate];
	if (self.needsRelease) {
		self.needsRelease = false;
		dispatch_semaphore_signal(self.navigationSemaphore);
	}
}

-(void) clearSubviews {
    for(UIView *vw in [self.navigationController.view subviews]) {
        [vw removeFromSuperview];
    }
}

-(UIView*) view {
	return self.navigationController.view;
}
-(void) setBounds:(CGRect) bounds {
    _bounds = bounds;
    self.navigationController.view.bounds = bounds;
}

- (CGRect) screenBoundsForDisplayMode:(NSString*) displayMode {
    
    CGRect bounds = _bounds;
    
    if([displayMode isEqualToString:@"PUSH"]) {
        bounds.size.height -= 44;
    } else if([displayMode isEqualToString:@"REPLACE"] && [self.navigationController.viewControllers count] > 1) {
        // full screen when page will show
        bounds.size.height += 44;
    } else if([[self.navigationController viewControllers] count] == 1 && [displayMode isEqualToString:@"POP"]) {
        // full screen when page will show
        bounds.size.height += 44;
    }
	return bounds;
}

-(void)setNavigationController:(UINavigationController *)navigationController {
    if (_navigationController != navigationController) {
        [_navigationController release];
        _navigationController = [navigationController retain];
        _navigationController.delegate = self;
        _navigationController.navigationItem.title = self.title;
    }
}

- (void)showActivityIndicator {
    
	if(self.activityIndicatorCount == 0) {
		// determine the maximum bounds of the screen
		CGRect bounds = [UIScreen mainScreen].applicationFrame;
		MBActivityIndicator *blocker = [[[MBActivityIndicator alloc] initWithFrame:bounds] autorelease];
		[_navigationController.parentViewController.view addSubview:blocker];
	}
	self.activityIndicatorCount ++;
    
}

- (void)hideActivityIndicator {
	if(self.activityIndicatorCount > 0) {
		self.activityIndicatorCount--;
		
		if(self.activityIndicatorCount == 0) {
			UIView *top = [_navigationController.parentViewController.view.subviews lastObject];
			if ([top isKindOfClass:[MBActivityIndicator class]])
				[top removeFromSuperview];
		}
	}
    
}

- (NSString *)dialogName {
    return self.dialogController.name;
}

- (void)resetView {
    // Manually reset the viewControllers array because that's the only way to remove the rootViewController
    //self.navigationController.viewControllers = [NSArray array];
	self.markedForReset = true;
}

// This needs to be done after the page (viewController) is visible, because before that we have nothing to set the close button to
- (void)setupCloseButtonForPage:(MBPage *)page {
    if (self.dialogController.closable) {
        NSString *closeButtonTitle = MBLocalizedString(@"closeButtonTitle");
        UIBarButtonItem *closeButton = [[[UIBarButtonItem alloc] initWithTitle:closeButtonTitle style:UIBarButtonItemStyleBordered target:self action:@selector(closeButtonPressed:)] autorelease];
        [page.viewController.navigationItem setRightBarButtonItem:closeButton animated:YES];
    }
}

- (void)closeButtonPressed:(id)sender {
    NSString *outcomeName = @"OUTCOME-end_modal";
    MBOutcome *outcome = [[[MBOutcome alloc] initWithOutcomeName:outcomeName document:nil pageStackName:self.name] autorelease];
    [[MBApplicationController currentInstance] handleOutcome:outcome];
}

@end
