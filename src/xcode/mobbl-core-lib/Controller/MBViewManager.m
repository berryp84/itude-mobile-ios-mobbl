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

#import "MBViewManager.h"

#import "MBDialogDefinition.h"
#import "MBDialogController.h"
#import "MBPageStackDefinition.h"
#import "MBPageStackController.h"

#import "MBOutcomeDefinition.h"
#import "MBOutcome.h"

#import "MBPage.h"
#import "MBAlert.h"

#import "MBConfigurationDefinition.h"
#import "MBMetadataService.h"
#import "MBResourceService.h"

#import "MBActivityIndicator.h"
#import "MBSpinner.h"

#import "MBLocalizationService.h"
#import "MBBasicViewController.h"
#import "MBTransitionStyle.h"

#import "MBFontCustomizer.h"

#import "MBMacros.h"

// Used to get a stylehandler to style navigationBar
#import "MBStyleHandler.h"
#import "MBViewBuilderFactory.h"

#import "MBEmptyContentViewWrapper.h"
#import "MBSlidingMenuContentViewWrapper.h"

#import <objc/runtime.h>
#import <objc/message.h>

@interface MBViewManager() {
	UIWindow *_window;
	UITabBarController *_tabController;
    
	MBDialogManager *_dialogManager;
    
	UIAlertView *_currentAlert; // TODO: I don't see why we need the currentAlert??
    
    NSMutableDictionary *_activityIndicatorCounts;
	int _activityIndicatorCount;
}

@property (nonatomic, retain) NSMutableDictionary *activityIndicatorCounts;

- (void) clearWindow;
- (void) resetView;
- (void) showAlertView:(MBPage*) page;

@end

@implementation MBViewManager

@synthesize window = _window;
@synthesize tabController = _tabController;
@synthesize dialogManager = _dialogManager;
@synthesize currentAlert = _currentAlert;
@synthesize activityIndicatorCounts = _activityIndicatorCounts;

- (id) init {
	self = [super init];
	if (self != nil) {
        _window = [[UIWindow alloc] initWithFrame: [[UIScreen mainScreen]bounds]];
		_contentViewWrapper = [[[MBApplicationFactory sharedInstance] createContentViewWrapper] retain];
        self.activityIndicatorCounts = [[NSMutableDictionary new] autorelease];
		self.dialogManager = [[[MBDialogManager alloc] initWithDelegate:self] autorelease];
	}
	return self;
}

- (void) dealloc {
	[_contentViewWrapper release];
	[_window release];
	[_tabController release];
	[_dialogManager release];
	[_currentAlert release];
    [_activityIndicatorCounts release];
	[super dealloc];
}

-(void) showPage:(MBPage*) page displayMode:(NSString*) displayMode {
    [self showPage:page displayMode:displayMode transitionStyle:nil];
}

-(void) showPage:(MBPage*) page displayMode:(NSString*) displayMode transitionStyle:(NSString *) transitionStyle  {
    
    DLog(@"ViewManager: showPage name=%@ pageStack=%@ mode=%@ type=%i", page.pageName, page.pageStackName, displayMode, page.pageType);
    
	if(page.pageType == MBPageTypesErrorPage || [@"POPUP" isEqualToString:displayMode]) {
		[self showAlertView: page];
	}
    else {
        
        // Backwards compatibility: If the pageStackName of the page is the same as the active one AND there is a displaymode,
        // we can assume that the developer want's to show the dialog in a modal presentation.
        if (displayMode.length > 0 && [page.pageStackName isEqualToString:self.dialogManager.activePageStackName]) {
            if([C_DIALOG_DECORATOR_TYPE_MODAL isEqualToString:displayMode]) {
                page.pageStackName = @"PAGESTACK-modal";
            }
            else if([C_DIALOG_DECORATOR_TYPE_MODAL_CLOSABLE isEqualToString:displayMode]) {
                page.pageStackName = @"PAGESTACK-modal-closable";
            }
            else if([C_DIALOG_DECORATOR_TYPE_MODALCURRENTCONTEXT isEqualToString:displayMode]) {
                page.pageStackName = @"PAGESTACK-modalcurrentcontext";
            }
            else if([C_DIALOG_DECORATOR_TYPE_MODALCURRENTCONTEXT_CLOSABLE isEqualToString:displayMode]) {
                page.pageStackName = @"PAGESTACK-modalcurrentcontext-closable";
            }
            else if([C_DIALOG_DECORATOR_TYPE_MODALFORMSHEET isEqualToString:displayMode]) {
                page.pageStackName = @"PAGESTACK-modalformsheet";
            }
            else if([C_DIALOG_DECORATOR_TYPE_MODALFORMSHEET_CLOSABLE isEqualToString:displayMode]) {
                page.pageStackName = @"PAGESTACK-modalformsheet-closable";
            }
            else if([C_DIALOG_DECORATOR_TYPE_MODALFULLSCREEN isEqualToString:displayMode]) {
                page.pageStackName = @"PAGESTACK-modalfullscreen";
            }
            else if([C_DIALOG_DECORATOR_TYPE_MODALFULLSCREEN_CLOSABLE isEqualToString:displayMode]) {
                page.pageStackName = @"PAGESTACK-modalfullscreen-closable";
            }
            else if([C_DIALOG_DECORATOR_TYPE_MODALPAGESHEET isEqualToString:displayMode]) {
                page.pageStackName = @"PAGESTACK-modalpagesheet";
            }
            else if([C_DIALOG_DECORATOR_TYPE_MODALPAGESHEET_CLOSABLE isEqualToString:displayMode]) {
                page.pageStackName = @"PAGESTACK-modalpagesheet-closable";
            }
        }
        
        // The page can get a pageStackName from an outcome but if this is not the case we set the activePageStackName
        else if (page.pageStackName.length == 0) {
            page.pageStackName = self.dialogManager.activePageStackName;
        }
        
        MBDialogController *dialogController = [self.dialogManager dialogForPageStackName:page.pageStackName];
        
        /** Show/present the dialogController if it is unvisible
         * NOTE: Comparing the activeDialogName does not work for initialOutcomes, because the MBFireInitialOutcomes activates the first pageStack by default.
         * Solution: Activate the first tab, and after that activate the modal (if it is the first controller to be activated */
        if (![[self.dialogManager activeDialogName] isEqualToString:dialogController.name]) {
            [[[MBViewBuilderFactory sharedInstance] dialogDecoratorFactory] presentDialog:dialogController withTransitionStyle:transitionStyle];
        }
        
        // Activate the pageStack if it is not the active one
        if (![page.pageStackName isEqualToString:self.dialogManager.activePageStackName]) {
            [self.dialogManager activatePageStackWithName:page.pageStackName];
        }
        
        // Show page on pageStack
        MBPageStackController *pageStackController = [dialogController pageStackControllerWithName:page.pageStackName];
        [pageStackController showPage:page displayMode:displayMode transitionStyle:transitionStyle];
        
	}
}

// After delegate didloaddialogs
- (void)createTabbarForDialogControllers:(NSArray *)dialogControllers {
    
    
    MBDialogController *firstDialogController = nil;
    // Should create tabbar
    if([dialogControllers count] > 1 && [self shouldCreateTabBarForDialogsControllers:dialogControllers])
	{
        // Build the tabbar
        self.tabController = [[[UITabBarController alloc] init] autorelease];
        self.tabController.delegate = self;
        [self setContentViewController:self.tabController];
        
        // Build the tabs
        int idx = 0;
        NSMutableArray *tabs = [NSMutableArray new];
        for (MBDialogController *dialogController in dialogControllers) {
            if ([dialogController showAsTab]) {
                // Create a tabbarProperties
                UIViewController *viewController = dialogController.rootViewController;
                UIImage *tabImage = [[MBResourceService sharedInstance] imageByID: dialogController.iconName];
                NSString *tabTitle = MBLocalizedString(dialogController.title);
                UITabBarItem *tabBarItem = [[[UITabBarItem alloc] initWithTitle:tabTitle image:tabImage tag:idx] autorelease];
                viewController.tabBarItem = tabBarItem;
                
                [tabs addObject:viewController];
                
                if (idx == 0) {
                    firstDialogController = dialogController;
                }
                
                idx ++;
            }
        }
        
        // Set the tabs to the tabbar
        [self.tabController setViewControllers: tabs animated: YES];
        [[self.tabController moreNavigationController] setHidesBottomBarWhenPushed:FALSE];
        self.tabController.moreNavigationController.delegate = self;
        self.tabController.customizableViewControllers = nil;
        [tabs release];
        
        [[[MBViewBuilderFactory sharedInstance] styleHandler] styleTabBarController:self.tabController];
    }
    
    // Single page mode
    else if([dialogControllers count] > 0) {
        
        // Search for the only dialogController with attribute 'showAs="TAB"'.
        MBDialogController *dialogController = nil;
        for (MBDialogController *currentDialogContoller in dialogControllers) {
            if ([currentDialogContoller showAsTab]) {
                dialogController = currentDialogContoller;
                break;
            }
        }
        
        // Take the first dialogController if no dialogController with attribute 'showAs="TAB"' is found.
        if (!dialogController) {
            dialogController = [dialogControllers objectAtIndex:0];
        }
        
        [self setContentViewController:dialogController.rootViewController];
        firstDialogController = dialogController;
    }
    
    
    // Ensure we select a pageStack
    if (firstDialogController) {
        MBPageStackController *pageStackController = [firstDialogController.pageStackControllers objectAtIndex:0];
        [self.dialogManager activatePageStackWithName:pageStackController.name];
    }
    
    // Make sure we activate ourselve when we have something to show (initially)
    if (!self.window.isKeyWindow) {
        [self makeKeyAndVisible];
    }
}


#pragma mark -
#pragma mark MBAlert and UIAlertView management

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
    // Show a alert on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert.alertView show];
    });
}



- (void) resetView {
    self.tabController = nil;
    [self clearWindow];
}


#pragma mark -
#pragma mark View managing

- (void) resetViewPreservingCurrentPageStack {
    // TODO: This will probably fail because Dialogs (ViewControllers) have nested PageStacks (NavigationControllers)
	for (UIViewController *controller in [_tabController viewControllers]){
		if ([controller isKindOfClass:[UINavigationController class]]) {
			[(UINavigationController *) controller popToRootViewControllerAnimated:YES];
		}
	}
}

- (void) makeKeyAndVisible {
	[self.tabController.moreNavigationController popToRootViewControllerAnimated:NO];
	[self.window makeKeyAndVisible];
}

- (void)setContentViewController:(UIViewController *)viewController {
    [self clearWindow];
    [self.window setRootViewController:[self.contentViewWrapper wrapController:viewController]];
}

// Remove every view that is not the activityIndicatorView
-(void) clearWindow {
    for(UIView *view in [self.window subviews]) {
		if(![view isKindOfClass:[MBActivityIndicator class]]) [view removeFromSuperview];
	}
}


#pragma mark -
#pragma mark Presenting and Dismissing (modal) ViewControllers

- (void)presentViewController:(UIViewController *)controller fromViewController:(UIViewController *)fromViewController animated:(BOOL)animated {
    [self presentViewController:controller fromViewController:fromViewController animated:animated completion:nil];
}

- (void)presentViewController:(UIViewController *)controller fromViewController:(UIViewController *)fromViewController animated:(BOOL)animated completion:(void (^)(void))completion {
    // iOS 6.0 and up
    if ([fromViewController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        [fromViewController presentViewController:controller animated:animated completion:completion];
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
    [self dismisViewController:controller animated:animated completion:nil];
}

- (void)dismisViewController:(UIViewController *)controller animated:(BOOL)animated completion:(void (^)(void))completion {
    // iOS 6.0 and up
    if ([controller respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [controller dismissViewControllerAnimated:animated completion:completion];
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


#pragma mark -
#pragma mark Activity Indicator management

- (void)showActivityIndicator {
    [self showActivityIndicatorOnDialog:nil withMessage:nil];
}

- (void)showActivityIndicatorWithMessage:(NSString *)message {
    [self showActivityIndicatorOnDialog:nil withMessage:message];
}

- (void)showActivityIndicatorOnDialog:(MBDialogController *)dialogController {
    [self showActivityIndicatorOnDialog:dialogController withMessage:nil];
}


- (void)showActivityIndicatorOnDialog:(MBDialogController *)dialogController withMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *topMostVisibleViewController = (dialogController) ? dialogController.rootViewController : [self topMostVisibleViewController];
        if(_activityIndicatorCount == 0) {
            CGRect bounds = topMostVisibleViewController.view.bounds;
            MBActivityIndicator *blocker = [[[MBActivityIndicator alloc] initWithFrame:bounds] autorelease];
            if (message) {
                [blocker showWithMessage:message];
            }
            
            [topMostVisibleViewController.view addSubview:blocker];
        } else {
            for (UIView *subview in [[topMostVisibleViewController view] subviews]) {
                if ([subview isKindOfClass:[MBActivityIndicator class]]) {
                    MBActivityIndicator *indicatorView = (MBActivityIndicator *)subview;
                    [indicatorView setMessage:message];
                    break;
                }
            }
            
        }
        _activityIndicatorCount ++;
    });
}

- (void)hideActivityIndicator {
    [self hideActivityIndicatorOnDialog:nil];
}

- (void)hideActivityIndicatorOnDialog:(MBDialogController *)dialogController {
	if(_activityIndicatorCount > 0) {
		_activityIndicatorCount--;
		
		if(_activityIndicatorCount == 0) {
            UIViewController *topMostVisibleViewController = (dialogController) ? dialogController.rootViewController : [self topMostVisibleViewController];
            for (UIView *subview in [[topMostVisibleViewController view] subviews]) {
                if ([subview isKindOfClass:[MBActivityIndicator class]]) {
					dispatch_async(dispatch_get_main_queue(), ^{
                    [subview removeFromSuperview];
					});
                }
            }
		}
	}
}


#pragma mark -
#pragma mark Util

-(CGRect) bounds {
    return [self.window bounds];
}


- (MBViewState) currentViewState {
	// Currently fullscreen is not implemented
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
    // Suppress the deprecation warning
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    else if (self.window.rootViewController.modalViewController) {
        return self.window.rootViewController.modalViewController;
    }
#pragma clang diagnostic pop
    
    // If all else fails, return the rootViewcontroller of the Window
    return self.window.rootViewController;
    
}

/**
 * Returns TRUE if two or more DialogControllers have defined 'showAs="TAB"'
 */
- (BOOL)shouldCreateTabBarForDialogsControllers:(NSArray *)dialogControllers {
    NSInteger numberOfShowAsTabs = 0;
    for (MBDialogController *dialogController in dialogControllers) {
        if ([dialogController showAsTab]) {
            numberOfShowAsTabs ++;
            if (numberOfShowAsTabs > 1) {
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	self.currentAlert = nil;
}


#pragma mark -
#pragma mark UINavigationControllerDelegate

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
#pragma mark UITabBarControllerDelegate

-(BOOL) tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
	return YES;
}

// Method is called when the tabBar will be edited by the user (when the user presses the edid-button on the more-page).
// It is used to update the style of the "Edit" navigationBar behind the Edit-button
- (void)tabBarController:(UITabBarController *)tabBarController willBeginCustomizingViewControllers:(NSArray *)viewControllers {
	// Get the navigationBar from the edit-view behind the more-tab and apply style to it.
    UINavigationBar *navBar = [[[tabBarController.view.subviews objectAtIndex:1] subviews] objectAtIndex:0];
	[[[MBViewBuilderFactory sharedInstance] styleHandler] styleNavigationBar:navBar];
}

-(void) tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController{
    
    // Set active dialog/pageStack name
    for (MBDialogController *dialogController in [self.dialogManager.dialogControllers allValues]) {
        if (viewController == dialogController.rootViewController) {
            if ([viewController isKindOfClass:[MBBasicViewController class]]) {
                MBBasicViewController *basicViewController = (MBBasicViewController*)viewController;
                [self.dialogManager activatePageStackWithName:basicViewController.pageStackController.name];
            }
            else {
                [self.dialogManager activateDialogWithName:dialogController.name];
            }
            break;
        }
    }
}


#pragma mark -
#pragma mark MBDialogManagerDelegate

- (void)didLoadDialogControllers:(NSArray *)dialogControllers {
    [self createTabbarForDialogControllers:dialogControllers];
}

- (void)didEndPageStackWithName:(NSString*) pageStackName {
    // TODO: Remove???
}

- (void)didActivatePageStack:(MBPageStackController *)pageStackController inDialog:(MBDialogController *)dialogController {
    
    // If we have more than one viewController visible
    if (self.tabController) {
        // Only set the selected tab if realy necessary; because it messes up the more navigation controller
        NSInteger idx = _tabController.selectedIndex;
        NSInteger shouldBe = [_tabController.viewControllers indexOfObject: dialogController.rootViewController];
        
        if(idx != shouldBe && shouldBe!=NSNotFound) {
            [self.tabController setSelectedIndex:shouldBe];
        }
    }
    
}


@end
