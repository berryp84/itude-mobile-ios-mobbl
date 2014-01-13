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

//  MBSlidingMenuContentViewWrapper.h
//  kitchensink-app
//  Created by Pjotter Tommassen on 2013/25/11.

#import <Foundation/Foundation.h>
#import "MBContentViewWrapper.h"

@protocol MBSlidingMenuDelegate <NSObject>

@optional
-(void)menuOpened;
-(void)menuClosed;

@end

@interface MBSlidingMenuContentViewWrapper : UIViewController <MBContentViewWrapper>

@property (nonatomic, assign) BOOL shouldShowMenu;

-(void)addDelegate:(id<MBSlidingMenuDelegate>)delegate;
-(void)removeDelegate:(id<MBSlidingMenuDelegate>)delegate;

-(UIView*)getMenuView;

- (BOOL)menuVisible;

- (void)closeMenu;
- (void)openMenu;

@end
