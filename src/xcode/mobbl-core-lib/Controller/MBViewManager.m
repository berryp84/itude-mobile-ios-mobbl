/*
 * (C) Copyright ItudeMobile.
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

#import "MBOrderedMutableDictionary.h"
#import "MBMacros.h"
#import "MBViewManager.h"
#import "MBPageStackDefinition.h"
#import "MBDialogDefinition.h"
#import "MBPageStackController.h"
#import "MBDialogController.h"
#import "MBOutcomeDefinition.h"
#import "MBOutcome.h"
#import "MBMetadataService.h"
#import "MBPage.h"
#import "MBAlert.h"
#import "MBResourceService.h"
#import "MBActivityIndicator.h"
#import "MBConfigurationDefinition.h"
#import "MBSpinner.h"
#import "MBLocalizationService.h"
#import "MBBasicViewController.h"
#import "MBTransitionStyle.h"

#import "MBFontCustomizer.h"

// Used to get a stylehandler to style navigationBar
#import "MBStyleHandler.h"
#import "MBViewBuilderFactory.h"

#import <objc/runtime.h>
#import <objc/message.h>

@interface MBViewManager() {
	UIWindow *_window;
	UITabBarController *_tabController;
    MBOrderedMutableDictionary *_dialogControllers;
	NSMutableDictionary *_pageStackControllers;
	NSMutableDictionary *_activityIndicatorCounts;
	NSMutableArray *_pageStackControllersOrdered;
	NSMutableArray *_sortedNewPageStackNames;
	NSString *_activePageStackName;
	NSString *_activeDialogName;
	UIAlertView *_currentAlert;
	UINavigationController *_modalController;
	int _activityIndicatorCount;
}

@property (nonatomic, retain) MBOrderedMutableDictionary *dialogControllers;

-(MBPageStackController*) pageStackControllerWithName:(NSString*) name;
- (void) clearWindow;
- (void) resetView;
- (void) showAlertView:(MBPage*) page;
- (void) addPageToPageStack:(MBPage *) page displayMode:(NSString*) displayMode transitionStyle:(NSString *)transitionStyle selectPageStack:(BOOL) shouldSelectPageStack;
@end

@implementation MBViewManager

@synthesize window = _window;
@synthesize tabController = _tabController;
@synthesize activePageStackName = _activePageStackName;
@synthesize activeDialogName = _activeDialogName;
@synthesize currentAlert = _currentAlert;
@synthesize dialogControllers = _dialogControllers;

- (id) init {
	self = [super init];
	if (self != nil) {
		_activityIndicatorCounts = [NSMutableDictionary new];
        _window = [[UIWindow alloc] initWithFrame: [[UIScreen mainScreen]bounds]];
		_sortedNewPageStackNames = [NSMutableArray new];
        self.dialogControllers = [[MBOrderedMutableDictionary new] autorelease];
        [self resetView];
	}
	return self;
}

- (void) dealloc {
	[_pageStackControllers release];
    [_dialogControllers release];
	[_window release];
	[_tabController release];
	[_sortedNewPageStackNames release];
	[_activityIndicatorCounts release];
	[_activePageStackName release];
	[_activeDialogName release];
	[_currentAlert release];
	[_modalController release];
	[super dealloc];
}

-(void) showPage:(MBPage*) page displayMode:(NSString*) displayMode {
    [self showPage:page displayMode:displayMode transitionStyle:nil selectPageStack:TRUE];
}

- (void) showPage:(MBPage*) page displayMode:(NSString*) displayMode transitionStyle:(NSString *) transitionStyle {
    [self showPage:page displayMode:displayMode transitionStyle:transitionStyle selectPageStack:TRUE];
}

-(void) showPage:(MBPage*) page displayMode:(NSString*) displayMode selectPageStack:(BOOL) shouldSelectPageStack {
    [self showPage:page displayMode:displayMode transitionStyle:nil selectPageStack:shouldSelectPageStack];
}


-(void) showPage:(MBPage*) page displayMode:(NSString*) displayMode transitionStyle:(NSString *) transitionStyle selectPageStack:(BOOL) shouldSelectPageStack {
    
    
    DLog(@"ViewManager: showPage name=%@ pageStack=%@ mode=%@ type=%i", page.pageName, page.pageStackName, displayMode, page.pageType);

	if(page.pageType == MBPageTypesErrorPage || [@"POPUP" isEqualToString:displayMode]) {
		[self showAlertView: page];
	}
	else if(_modalController == nil &&
			([@"MODAL" isEqualToString:displayMode] || 
			 [@"MODALWITHCLOSEBUTTON" isEqualToString:displayMode] || 
			 [@"MODALFORMSHEET" isEqualToString:displayMode] ||
			 [@"MODALFORMSHEETWITHCLOSEBUTTON" isEqualToString:displayMode] || 
			 [@"MODALPAGESHEET" isEqualToString:displayMode] ||
			 [@"MODALPAGESHEETWITHCLOSEBUTTON" isEqualToString:displayMode] ||
			 [@"MODALFULLSCREEN" isEqualToString:displayMode] ||
			 [@"MODALFULLSCREENWITHCLOSEBUTTON" isEqualToString:displayMode] || 
			 [@"MODALCURRENTCONTEXT" isEqualToString:displayMode] ||
			 [@"MODALCURRENTCONTEXTWITHCLOSEBUTTON" isEqualToString:displayMode])) {
                
                BOOL addCloseButton = NO;
                UIModalPresentationStyle modalPresentationStyle = UIModalPresentationFormSheet;
                if ([@"MODALFORMSHEET" isEqualToString:displayMode])			[_modalController setModalPresentationStyle:UIModalPresentationFormSheet];
                else if ([@"MODALPAGESHEET" isEqualToString:displayMode])		[_modalController setModalPresentationStyle:UIModalPresentationPageSheet];
                else if ([@"MODALFULLSCREEN" isEqualToString:displayMode])		[_modalController setModalPresentationStyle:UIModalPresentationFullScreen];
                else if ([@"MODALCURRENTCONTEXT" isEqualToString:displayMode])	[_modalController setModalPresentationStyle:UIModalPresentationCurrentContext];
                else if ([@"MODALWITHCLOSEBUTTON" isEqualToString:displayMode]) addCloseButton = YES;
                else if ([@"MODALFORMSHEETWITHCLOSEBUTTON" isEqualToString:displayMode]) {
                    addCloseButton = YES;
                    modalPresentationStyle = UIModalPresentationFormSheet;
                }
                else if ([@"MODALPAGESHEETWITHCLOSEBUTTON" isEqualToString:displayMode]) {
                    addCloseButton = YES;
                    modalPresentationStyle = UIModalPresentationPageSheet;
                }
                else if ([@"MODALFULLSCREENWITHCLOSEBUTTON" isEqualToString:displayMode]) {
                    addCloseButton = YES;
                    modalPresentationStyle = UIModalPresentationFullScreen;
                }
                else if ([@"MODALCURRENTCONTEXTWITHCLOSEBUTTON" isEqualToString:displayMode]) {
                    addCloseButton = YES;
                    modalPresentationStyle = UIModalPresentationCurrentContext;
                }
                
                // TODO: support nested modal pageStacks
                _modalController = [[UINavigationController alloc] initWithRootViewController:[page viewController]];
                _modalController.modalPresentationStyle = modalPresentationStyle;
                [[[MBViewBuilderFactory sharedInstance] styleHandler] styleNavigationBar:_modalController.navigationBar];
                
                if (addCloseButton) {
                    NSString *closeButtonTitle = MBLocalizedString(@"closeButtonTitle");
                    UIBarButtonItem *closeButton = [[[UIBarButtonItem alloc] initWithTitle:closeButtonTitle style:UIBarButtonItemStyleBordered target:self action:@selector(endModalPageStack)] autorelease];
                    [_modalController.topViewController.navigationItem setRightBarButtonItem:closeButton animated:YES];
                }
                                                
                // If tabController is nil, there is only one viewController
                if (_tabController) {
                    [[[MBApplicationFactory sharedInstance] transitionStyleFactory] applyTransitionStyle:transitionStyle withMovement:MBTransitionMovementPush forViewController:_tabController];
                    page.transitionStyle = transitionStyle;
                    [self presentViewController:_modalController fromViewController:_tabController animated:YES];
                }
                else {
                    MBPageStackController *pageStackController = [self pageStackControllerWithName:[self activePageStackName]];
                    [[[MBApplicationFactory sharedInstance] transitionStyleFactory] applyTransitionStyle:transitionStyle withMovement:MBTransitionMovementPush forViewController:_modalController];
                    page.transitionStyle = transitionStyle;
                    [self presentViewController:_modalController fromViewController:pageStackController.navigationController animated:YES];
                }
                // tell other view controllers that they have been dimmed (and auto-refresh controllers may need to stop refreshing)
                NSDictionary * dict = [NSDictionary dictionaryWithObject:_modalController forKey:@"modalViewController"];
                [[NSNotificationCenter defaultCenter] postNotificationName:MODAL_VIEW_CONTROLLER_PRESENTED object:self userInfo:dict];
            }
	else if(_modalController != nil) {
		UIViewController *currentViewController = [page viewController];
        
        // Apply transition. Pushing on the navigation stack
        id<MBTransitionStyle> transition = [[[MBApplicationFactory sharedInstance] transitionStyleFactory] transitionForStyle:transitionStyle];
        [transition applyTransitionStyleToViewController:_modalController forMovement:MBTransitionMovementPush];
        page.transitionStyle = transitionStyle;
		[_modalController pushViewController:currentViewController animated:[transition animated]];
		
		// See if the first viewController has a barButtonItem that can close the controller. If so, add it to the new controller
		UIViewController *rootViewController = [_modalController.viewControllers objectAtIndex:0];		
		UIBarButtonItem *rootViewCtrlRightBarButtonItem = rootViewController.navigationItem.rightBarButtonItem;
        UIBarButtonItem *currentViewCtrlBarButtonItem = currentViewController.navigationItem.rightBarButtonItem;
		NSString *closeButtonTitle = MBLocalizedString(@"closeButtonTitle");
		if ([rootViewCtrlRightBarButtonItem.title isEqualToString:closeButtonTitle] && (!currentViewCtrlBarButtonItem
            || [currentViewCtrlBarButtonItem isKindOfClass:[MBFontCustomizer class]])) {
            UIBarButtonItem *closeButton = [[[UIBarButtonItem alloc] initWithTitle:closeButtonTitle style:UIBarButtonItemStyleBordered target:self action:@selector(endModalPageStack)] autorelease];
            [currentViewController.navigationItem setRightBarButtonItem:closeButton animated:YES];
		}
		
		// Workaround for view delegate method calls in modal views Controller (BINCKAPPS-426 and MOBBL-150)
		[currentViewController performSelector:@selector(viewWillAppear:) withObject:nil afterDelay:0];
		[currentViewController performSelector:@selector(viewDidAppear:) withObject:nil afterDelay:0]; 
	}
    else {
		[self addPageToPageStack:page displayMode:displayMode transitionStyle:transitionStyle selectPageStack:shouldSelectPageStack];
	}
}	

-(void) addPageToPageStack:(MBPage *) page displayMode:(NSString*) displayMode transitionStyle:transitionStyle selectPageStack:(BOOL) shouldSelectPageStack {
    
    
    MBDialogDefinition *dialogDef = [[MBMetadataService sharedInstance] dialogDefinitionForPageStackName:page.pageStackName];
    MBDialogController *dialogController = [self dialogWithName:dialogDef.name];
    
    if (dialogController == nil) {
        dialogController = [self createDialogController:dialogDef];
        [self updateDisplay];
    }
    
    MBPageStackController *pageStackController = [dialogController pageStackControllerWithName:page.pageStackName];
    [pageStackController showPage:page displayMode:displayMode transitionStyle:transitionStyle];

	
	if(shouldSelectPageStack ) {
        [self activatePageStackWithName:page.pageStackName];
    }
}

- (MBDialogController *)createDialogController:(MBDialogDefinition *)definition {
    MBDialogController *dialogController = [self dialogWithName:definition.name];
    
    if (dialogController == nil) {
        dialogController = [[MBApplicationFactory sharedInstance] createDialogController:definition];
        [self.dialogControllers setValue:dialogController forKey:dialogController.name];
        for (MBPageStackController *stack in dialogController.pageStackControllers) {
            [_pageStackControllers setObject:stack forKey:stack.name];
            [_pageStackControllersOrdered addObject:stack.name];
        }
    }
    return dialogController;
}

-(void) showAlertView:(MBPage*) page {
	
	
	if(self.currentAlert == nil) {
		//			[self.currentAlert dismissWithClickedButtonIndex:0 animated: FALSE];
		
		NSString *title;
		NSString *message;
        MBDocument *document = page.document;
		
        if([document.name isEqualToString:DOC_SYSTEM_EXCEPTION] &&
           [[document valueForPath:PATH_SYSTEM_EXCEPTION_TYPE] isEqualToString:DOC_SYSTEM_EXCEPTION_TYPE_SERVER]) {
			title = [document valueForPath:PATH_SYSTEM_EXCEPTION_NAME];
			message = [document valueForPath:PATH_SYSTEM_EXCEPTION_DESCRIPTION];
		}
		
        else if([document.name isEqualToString:DOC_SYSTEM_EXCEPTION]) {
			title = MBLocalizedString(@"Application error");
			message = MBLocalizedString(@"Unknown error");
		}
		else {
			title = page.title;
			message = MBLocalizedString([document valueForPath:@"/message[0]/@text"]);
			if(message == nil) message = MBLocalizedString([document valueForPath:@"/message[0]/@text()"]);
		}
		
		_currentAlert = [[UIAlertView alloc]
							 initWithTitle: title
							 message: message
							 delegate:self
							 cancelButtonTitle:@"OK"
							 otherButtonTitles:nil];
		
        // Show a alert on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.currentAlert show];
        });
	}
}

- (void)showAlert:(MBAlert *)alert {
    [alert.alertView show];
}

- (void) presentViewController:(UIViewController *)controller fromViewController:(UIViewController *)fromViewController animated:(BOOL)animated {
    // iOS 6.0 and up
    if ([fromViewController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        [fromViewController presentViewController:controller animated:animated completion:nil];
    }
    // iOS 5.x and lower
    else {
        // Suppress the deprecation warning
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [fromViewController presentModalViewController:controller animated:animated];
        #pragma clang diagnostic pop
    }
    
}

- (void) dismisViewController:(UIViewController *)controller animated:(BOOL)animated {
    // iOS 6.0 and up
    if ([controller respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [controller dismissViewControllerAnimated:animated completion:nil];
    }
    // iOS 5.x and lower
    else {
        
        // Suppress the deprecation warning
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [controller dismissModalViewControllerAnimated:animated];
        #pragma clang diagnostic pop
    }
}

- (void) endModalPageStack {
	if(_modalController != nil) {
		// Hide any activity indicator for the modal stuff:
		while(_activityIndicatorCount >0) [self hideActivityIndicator];
		
        // If tabController is nil, there is only one viewController
        if (self.tabController) {
            [self dismisViewController:self.tabController animated:TRUE];
        }
        else {
            MBPageStackController *pageStackController = [self pageStackControllerWithName:[self activePageStackName]];
            // TODO: TransitionStyle!!!
            [self dismisViewController:pageStackController.navigationController animated:YES];
        }
        
		[[NSNotificationCenter defaultCenter] postNotificationName:MODAL_VIEW_CONTROLLER_DISMISSED object:self];
		[_modalController release];	
		_modalController = nil;
	}
}

- (void) popPageOnPageStackWithName:(NSString*) pageStackName {
    MBPageStackController *pageStackController = [self pageStackControllerWithName:pageStackName];
    
    // Determine transitionStyle
    MBBasicViewController *viewController = [pageStackController.navigationController.viewControllers lastObject];
    id<MBTransitionStyle> style = [[[MBApplicationFactory sharedInstance] transitionStyleFactory] transitionForStyle:viewController.page.transitionStyle];
    [pageStackController popPageWithTransitionStyle:viewController.page.transitionStyle animated:[style animated]];
}

-(void) endPageStackWithName:(NSString*) pageStackName keepPosition:(BOOL) keepPosition {
    MBPageStackController *result = [self pageStackControllerWithName:pageStackName]; 
    if(result != nil) {
        [_pageStackControllersOrdered removeObject:result];
        [_pageStackControllers removeObjectForKey: pageStackName];
        [self updateDisplay];
    }
	if(!keepPosition) [_sortedNewPageStackNames removeObject:pageStackName];
}

-(void) activatePageStackWithName:(NSString*) pageStackName {
	
	self.activePageStackName = pageStackName;
    
    MBPageStackController *pageStackController = [self pageStackControllerWithName:pageStackName];
    MBDialogController *dialogController = [self dialogWithName:[pageStackController dialogName]];
    
	self.activeDialogName = [dialogController name];
	
	
	// Only set the selected tab if realy necessary; because it messes up the more navigation controller
	NSInteger idx = _tabController.selectedIndex;
	NSInteger shouldBe = [_tabController.viewControllers indexOfObject:dialogController.rootViewController];
	
	// Apparently we need to select the tab. Only now we cannot do this for tabs that are on the more tab
	// because it destroys the navigation controller for some reason
	// TODO: Make selecting a pageStack work; even if it is nested within the more tab
    if(idx != shouldBe && shouldBe!=NSNotFound /* && shouldBe < FIRST_MORE_TAB_INDEX*/) {
		UIViewController *ctrl = [_tabController selectedViewController];
		[ctrl viewWillDisappear:FALSE];
		[_tabController setSelectedViewController: dialogController.rootViewController];
		[ctrl viewDidDisappear:FALSE];
	}
}

- (void) resetView {
    
    [_tabController release];
    [_pageStackControllers release];
    [_pageStackControllersOrdered release];

	[_modalController release];
    
    _tabController = nil;
	_modalController = nil;
    _pageStackControllers = [NSMutableDictionary new];
    _pageStackControllersOrdered = [NSMutableArray new];

    self.dialogControllers = [MBOrderedMutableDictionary new];
    [self clearWindow];
}


- (void) resetViewPreservingCurrentPageStack {
    // TODO: This will probably fail because Dialogs (ViewControllers) have nested PageStacks (NavigationControllers)
	for (UIViewController *controller in [_tabController viewControllers]){
		if ([controller isKindOfClass:[UINavigationController class]]) {
			[(UINavigationController *) controller popToRootViewControllerAnimated:YES];
		}
	}
	
}

-(MBPageStackController*) pageStackControllerWithName:(NSString*) name {
	return [_pageStackControllers objectForKey: name];
}

-(MBDialogController*) dialogWithName:(NSString*) name {
	return [self.dialogControllers objectForKey: name];
}

// Remove every view that is not the activityIndicatorView
-(void) clearWindow {
    for(UIView *view in [self.window subviews]) {
		if(![view isKindOfClass:[MBActivityIndicator class]]) [view removeFromSuperview];
	}
}

- (void)setContentViewController:(UIViewController *)viewController {
    [self clearWindow];
    [self.window setRootViewController:viewController];
}

/** 
 * Returns TRUE if two or more DialogControllers have defined 'showAs="TAB"'
 */
- (BOOL)shouldCreateTabBar {
    NSInteger numberOfShowAsTabs = 0;
    for (MBDialogController *dialogController in [self.dialogControllers allValues]) {
        if ([dialogController showAsTab]) {
            numberOfShowAsTabs ++;
            if (numberOfShowAsTabs > 1) {
                return YES;
            }
        }
    }
    return NO;
}

-(void) updateDisplay {

    BOOL shouldCreateTabBar = [self shouldCreateTabBar];
    // Should create tabbar
    if([self.dialogControllers count] > 1 && shouldCreateTabBar)
	{
        // Build the tabbar
		if(!self.tabController) {
			self.tabController = [[UITabBarController alloc] init];
			self.tabController.delegate = self;
			[[[MBViewBuilderFactory sharedInstance] styleHandler] styleTabBarController:self.tabController];
            [self setContentViewController:self.tabController];
		}		
		
        // Build the tabs
        int idx = 0;
        NSMutableArray *tabs = [NSMutableArray new];
        BOOL activeDialogNameStillVisible = FALSE;
        NSArray *visibleDialogControllers = [self visibleDialogControllers];
        for (MBDialogController *dialogController in visibleDialogControllers) {
            // Create a tabbarProperties
            UIViewController *viewController = dialogController.rootViewController;
            UIImage *tabImage = [[MBResourceService sharedInstance] imageByID: dialogController.iconName];
            NSString *tabTitle = MBLocalizedString(dialogController.title);
            UITabBarItem *tabBarItem = [[[UITabBarItem alloc] initWithTitle:tabTitle image:tabImage tag:idx] autorelease];
            viewController.tabBarItem = tabBarItem;
            
            [tabs addObject:viewController];
            
            idx ++;
                

            if (self.activeDialogName.length > 0 && [self.activeDialogName isEqualToString:dialogController.name]) {
                activeDialogNameStillVisible = YES;
            }
        }
        
        // Set the tabs to the tabbar
        [self.tabController setViewControllers: tabs animated: YES];
		[[self.tabController moreNavigationController] setHidesBottomBarWhenPushed:FALSE];
        self.tabController.moreNavigationController.delegate = self;
        self.tabController.customizableViewControllers = nil;
        [tabs release];
        
        // Ensure we select a pageStack when none is selected OR when the previous one is not visible anymore
        if (!activeDialogNameStillVisible && visibleDialogControllers.count > 0) {
            MBDialogController *firstVisibleDialogController = [visibleDialogControllers objectAtIndex:0];
            if (firstVisibleDialogController.pageStackControllers.count > 0) {
                MBPageStackController *pageStackController = [firstVisibleDialogController.pageStackControllers objectAtIndex:0];
                [self activatePageStackWithName:pageStackController.name];
            }
        }
        
    }
    
    // Single page mode
    else if([self.dialogControllers count] > 0) {
        
        // Search for the only dialogController with attribute 'showAs="TAB"'.
        MBDialogController *dialogController = nil;
        for (MBDialogController *currentDialogContoller in [self.dialogControllers allValues]) {
            if ([currentDialogContoller showAsTab]) {
                dialogController = currentDialogContoller;
                break;
            }
        }
        
        // Take the first dialogController if no dialogController with attribute 'showAs="TAB"' is found.
        if (!dialogController) {
            dialogController = [self.dialogControllers objectAtIndex:0];
        }
        
        [self setContentViewController:dialogController.rootViewController];
        
        // Ensure we select a pageStack when none is selected OR when the previous one is not visible anymore
        MBPageStackController *pageStackController = [dialogController.pageStackControllers objectAtIndex:0];
        [self activatePageStackWithName:pageStackController.name];
    }
}

- (NSArray *)visibleDialogControllers {
    NSMutableArray *visibleDialogControllers = [NSMutableArray array];
    for (MBDialogController *dialogController in [self.dialogControllers allValues]) {
        MBDialogDefinition *dialogDefinition = [[MBMetadataService sharedInstance] definitionForDialogName:dialogController.name];
        if ([dialogController showAsTab] && [dialogDefinition isPreConditionValid]) {
            [visibleDialogControllers addObject:dialogController];
        }
        
    }
    return visibleDialogControllers;
}

-(BOOL) tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
	return YES;
}

- (void)showActivityIndicator {
    [self showActivityIndicatorWithMessage:nil];
}

- (void)showActivityIndicatorWithMessage:(NSString *)message {
	if(_activityIndicatorCount == 0) {
		// determine the maximum bounds of the screen
        UIViewController *topMostVisibleViewController = [self topMostVisibleViewController];
        CGRect bounds = topMostVisibleViewController.view.bounds;
		MBActivityIndicator *blocker = [[[MBActivityIndicator alloc] initWithFrame:bounds] autorelease];
        if (message) {
            [blocker showWithMessage:message];
        }

        [topMostVisibleViewController.view addSubview:blocker];
	}else{
        
        for (UIView *subview in [[[self pageStackControllerWithName:self.activePageStackName] view] subviews]) {
            if ([subview isKindOfClass:[MBActivityIndicator class]]) {
                MBActivityIndicator *indicatorView = (MBActivityIndicator *)subview;
                [indicatorView setMessage:message];
                break;
            }
        }
    }
	_activityIndicatorCount ++;
}

- (void)hideActivityIndicator {
	if(_activityIndicatorCount > 0) {
		_activityIndicatorCount--;
		
		if(_activityIndicatorCount == 0) {
            UIViewController *topMostVisibleViewController = [self topMostVisibleViewController];
            for (UIView *subview in [[topMostVisibleViewController view] subviews]) {
                if ([subview isKindOfClass:[MBActivityIndicator class]]) {
                    [subview removeFromSuperview];
                }
            }
		}
	}
}

-(CGRect) bounds {
    return [self.window bounds];
}

- (void) notifyPageStackUsage:(NSString*) pageStackName {
	if(pageStackName != nil) {
		if(![_sortedNewPageStackNames containsObject:pageStackName]) {
			[_sortedNewPageStackNames addObject:pageStackName];
        }
	}
}

// Method is called when the tabBar will be edited by the user (when the user presses the edid-button on the more-page). 
// It is used to update the style of the "Edit" navigationBar behind the Edit-button
- (void)tabBarController:(UITabBarController *)tabBarController willBeginCustomizingViewControllers:(NSArray *)viewControllers {	
	// Get the navigationBar from the edit-view behind the more-tab and apply style to it. 
    UINavigationBar *navBar = [[[tabBarController.view.subviews objectAtIndex:1] subviews] objectAtIndex:0];
	[[[MBViewBuilderFactory sharedInstance] styleHandler] styleNavigationBar:navBar];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	self.currentAlert = nil;
}

- (MBViewState) currentViewState {
	// Currently fullscreen is not implemented
	if(_modalController != nil) return MBViewStateModal;
	if(_tabController != nil) return MBViewStateTabbed;
	return MBViewStatePlain;
}

- (UIViewController *)topMostVisibleViewController {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    // On iOS 5 and later: search for the topViewController
    if ([topController respondsToSelector:@selector(presentedViewController)]) {
        while (topController.presentedViewController) {
            topController = topController.presentedViewController;
        }
        return topController;
    }
    
    // Fallback scenario for iOS 4.3 and earlier
    else if (self.window.rootViewController.modalViewController) {
        return self.window.rootViewController.modalViewController;
    }
    
    // If all else fails, return the rootViewcontroller of the Window
    return self.window.rootViewController;
    
}

-(void) tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController{
    // Set active dialog name
    for (MBDialogController *dialogController in [self.dialogControllers allValues]) {
        if (viewController == dialogController.rootViewController) {
            self.activeDialogName = dialogController.name;
            break;
        }
    }
}

-(void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([viewController isKindOfClass:[MBBasicViewController class]])
    {
        MBBasicViewController* controller = (MBBasicViewController*) viewController;
        [controller.pageStackController didActivate];
    }
}

-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
 if ([viewController isKindOfClass:[MBBasicViewController class]])
    {
        MBBasicViewController* controller = (MBBasicViewController*) viewController;
        [controller.pageStackController willActivate];
        
    }
}

#pragma mark -
#pragma mark UIWindow delegate methods

- (void) makeKeyAndVisible {
	[self.tabController.moreNavigationController popToRootViewControllerAnimated:NO];
	[self.window makeKeyAndVisible];
}


@end