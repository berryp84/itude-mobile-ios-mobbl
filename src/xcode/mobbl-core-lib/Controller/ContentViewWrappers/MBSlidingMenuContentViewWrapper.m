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

//  MBSlidingMenuContentViewWrapper.m
//  kitchensink-app
//  Created by Pjotter Tommassen on 2013/25/11.

#import "MBSlidingMenuContentViewWrapper.h"
#import "MBViewManager.h"

#define SHADOW_SIZE 4
#define SHADOW_OFFSET -2

#define SLIDING_TIME 0.25f
#define PANEL_WIDTH 60

@interface MBSlidingMenuContentViewWrapper  () <UIGestureRecognizerDelegate>

@property (nonatomic, retain) UIViewController *mainController;
@property (nonatomic, assign) BOOL menuVisible;
@property (nonatomic, retain) NSMutableArray *delegates;
@property (nonatomic, retain) UIViewController *menuController;

@end

@implementation MBSlidingMenuContentViewWrapper

- (id)init
{
    self = [super init];
    if (self) {
        _delegates = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_delegates release];
	[super dealloc];
}

-(UIViewController *)wrapController:(UIViewController *)controller {
	if (self.mainController) {
		if (self.mainController == controller) return self;

		[self.mainController removeFromParentViewController ];
		[self.mainController.view removeFromSuperview ];
		self.mainController = nil;
	}

	self.mainController = controller;


	[self.view addSubview:self.mainController.view];
    [self addChildViewController:self.mainController];

    [controller didMoveToParentViewController:self];

	[self setupGestures];
	return self;
}



- (void)setupGestures
{
	UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(movePanel:)];
	[panRecognizer setMinimumNumberOfTouches:1];
	[panRecognizer setMaximumNumberOfTouches:1];
	[panRecognizer setDelegate:self];

	[self.mainController.view addGestureRecognizer:panRecognizer];
}


-(void)movePanel:(id)sender
{
	[[[(UITapGestureRecognizer*)sender view] layer] removeAllAnimations];

	CGPoint translatedPoint = [(UIPanGestureRecognizer*) sender translationInView:self.view];
	CGPoint velocity = [(UIPanGestureRecognizer*)sender velocityInView:[sender view]];

	if([(UIPanGestureRecognizer*) sender state] == UIGestureRecognizerStateBegan) {
		UIView *child = nil;

		if (velocity.x > 0) {
			child = [self getMenuView];
			[self.view sendSubviewToBack:child];
			[[sender view] bringSubviewToFront:[(UIPanGestureRecognizer *)sender view]];
		}
	}

	if([(UIPanGestureRecognizer*) sender state] == UIGestureRecognizerStateEnded) {
		if (!_shouldShowMenu) {
			[self closeMenu];
		} else if (_menuVisible) {
			[self openMenu];
		}
	}

	if([(UIPanGestureRecognizer*) sender state] == UIGestureRecognizerStateChanged) {
		if (velocity.x < 0 && !_menuVisible) return;

        CGFloat newCenterX = [sender view].center.x + translatedPoint.x;
        CGFloat viewWidth = [sender view].frame.size.width;
        CGFloat newLeft = newCenterX - viewWidth / 2;
        if (newLeft < 0) newCenterX = viewWidth / 2;


        if (!_shouldShowMenu && newLeft > viewWidth / 3) _shouldShowMenu = true;
        else if (_shouldShowMenu && newLeft < (viewWidth / 2)) _shouldShowMenu = false;
        
		[sender view].center = CGPointMake(newCenterX,	[sender view].center.y);
		[(UIPanGestureRecognizer*)sender setTranslation:CGPointMake(0, 0) inView:self.view];


	}
}

-(void)closeMenu {
	[UIView animateWithDuration:SLIDING_TIME delay:0 options:UIViewAnimationOptionBeginFromCurrentState
					 animations:^{
						 self.mainController.view.frame = CGRectMake(0, 0, self.mainController.view.frame.size.width, self.mainController.view.frame.size.height);
					 }
					 completion:^(BOOL finished){
						 [self resetMainView];
					 }];

}

-(void) openMenu {

    UIView *child = [self getMenuView];
    [self.view sendSubviewToBack:child];

    [UIView animateWithDuration:SLIDING_TIME delay:0 options:UIViewAnimationOptionBeginFromCurrentState
					 animations:^{
						 self.mainController.view.frame = CGRectMake(self.view.frame.size.width - PANEL_WIDTH, 0, self.mainController.view.frame.size.width, self.mainController.view.frame.size.height);
					 }
					 completion:^(BOOL finished){
						 if (finished) {
							 for (id<MBSlidingMenuDelegate> delegate in self.delegates) {
								 if ([delegate respondsToSelector:@selector(menuOpened)]) [delegate menuOpened];
							 }

						 }
					 }];
}

-(void)resetMainView {
	if (_menuController) {
		[self.menuController removeFromParentViewController];
		[self.menuController.view removeFromSuperview];
		self.menuController = nil;

		self.menuVisible = NO;
	}

	for (id<MBSlidingMenuDelegate> delegate in self.delegates) {
		if ([delegate respondsToSelector:@selector(menuClosed)]) [delegate menuClosed];
	}
}

-(UIView*) getMenuView {
	if (!_menuController) {
        self.menuController = [self createMenuController];
		self.menuController.view.frame = CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height);

        [self.view addSubview:self.menuController.view];
        [self addChildViewController:self.menuController];

        [self.menuController didMoveToParentViewController:self];
	}

    self.menuVisible = YES;

    return self.menuController.view;
}

-(void)addDelegate:(id<MBSlidingMenuDelegate>)delegate {
	[self.delegates addObject:delegate];
}

-(void)removeDelegate:(id<MBSlidingMenuDelegate>)delegate {
	[self.delegates removeObject:delegate];
}

-(UIViewController*)createMenuController {
	UIViewController *menu = [[[UIViewController alloc]init] autorelease];
	menu.view = [[[UIView alloc] init] autorelease];
	menu.view.backgroundColor = [UIColor redColor];
	return menu;
}

@end
